/*
 * @Author: Himmeltala
 * @Date: 2026-10-29 16:02:00
 * @LastEditors: Himmeltala
 * @LastEditTime: 2026-11-06 16:00:00
 * @FilePath: \scripts\check-plugins.mjs
 * @Description: 校验插件的 Claude 打包：清单与目录一致、技能可列出、提交闸门脚本可拦可放。
 */
import { readdirSync, readFileSync, existsSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const ROOT = fileURLToPath(new URL('..', import.meta.url))
let failures = 0

function check(condition, message) {
  if (condition) {
    console.log(`ok   ${message}`)
  } else {
    failures += 1
    console.log(`FAIL ${message}`)
  }
}

const marketplace = JSON.parse(readFileSync(join(ROOT, '.claude-plugin', 'marketplace.json'), 'utf8'))
const plugins = readdirSync(join(ROOT, 'plugins'), { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort()
const listed = marketplace.plugins.map((entry) => entry.name).sort()
check(JSON.stringify(listed) === JSON.stringify(plugins), `市场清单与目录一致 ${listed.join(',')}`)

for (const plugin of plugins) {
  const dir = join(ROOT, 'plugins', plugin)
  const manifest = JSON.parse(readFileSync(join(dir, '.claude-plugin', 'plugin.json'), 'utf8'))
  check(manifest.name === plugin, `${plugin} 清单名一致`)
  check(/^\d+\.\d+\.\d+/.test(manifest.version), `${plugin} 版本号 ${manifest.version}`)
  check(!existsSync(join(dir, 'package.json')) && !existsSync(join(dir, 'lib')), `${plugin} 无 DSH 残留`)

  const skills = readdirSync(join(dir, 'skills'), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort()
  check(skills.length > 0, `${plugin} 技能数量 ${skills.length}`)
}

// 提交闸门：临时建一对仓库，造出「本地落后远端」，落后时提交与推送都要拦下，
// 最新时代提交信息不设限制，普通命令放行。
const guardDir = join(ROOT, 'plugins', 'commit-guarding', 'hooks', 'scripts')
const sandbox = mkdtempSync(join(tmpdir(), 'check-plugins-'))
const origin = join(sandbox, 'origin.git')
const work = join(sandbox, 'work')
const other = join(sandbox, 'other')
const gitRun = (cwd, args) => spawnSync('git', ['-C', cwd, ...args], { encoding: 'utf8' })
const gitOk = (cwd, args) => {
  const run = gitRun(cwd, args)
  if (run.status !== 0) {
    failures += 1
    console.log(`FAIL 建临时仓库失败 ${args.join(' ')}: ${run.stderr}`)
    return false
  }
  return true
}

spawnSync('git', ['init', '-q', '--bare', '-b', 'main', origin])
spawnSync('git', ['clone', '-q', origin, work])
gitOk(work, ['config', 'user.email', 'check@test'])
gitOk(work, ['config', 'user.name', 'check'])
writeFileSync(join(work, 'f.txt'), 'alpha\n')
gitOk(work, ['add', 'f.txt'])
gitOk(work, ['commit', '-q', '-m', '初始文件'])
gitOk(work, ['push', '-q', '-u', 'origin', 'main'])

const payload = (command, cwd) => JSON.stringify({
  session_id: 'check',
  hook_event_name: 'PreToolUse',
  tool_name: 'Bash',
  cwd,
  tool_input: { command },
})
const runGuard = (script, command, cwd = work) =>
  spawnSync('bash', [join(guardDir, script)], { input: payload(command, cwd), encoding: 'utf8' })

const allowed = runGuard('git-commit-guard.sh', 'ls -la')
check(allowed.status === 0, `git 闸门放行普通命令 exit=${allowed.status}`)
const messageOk = runGuard('git-commit-guard.sh', 'git commit -m "feat(login): 加个功能"')
check(messageOk.status === 0, `git 闸门放行合规提交信息 exit=${messageOk.status}`)
const messageBad = runGuard('git-commit-guard.sh', 'git commit -m "加个功能"')
check(messageBad.status === 2, `git 闸门拦下无类型的提交信息 exit=${messageBad.status}`)

spawnSync('git', ['clone', '-q', origin, other])
gitOk(other, ['config', 'user.email', 'check@test'])
gitOk(other, ['config', 'user.name', 'check'])
writeFileSync(join(other, 'f.txt'), 'beta\n')
gitOk(other, ['commit', '-q', '-am', '别人先推了一条'])
gitOk(other, ['push', '-q'])

const behindCommit = runGuard('git-commit-guard.sh', 'git commit -m "chore: 测试"')
check(behindCommit.status === 2, `git 闸门拦下落后的提交 exit=${behindCommit.status}`)
const behindPush = runGuard('git-commit-guard.sh', 'git push')
check(behindPush.status === 2, `git 闸门拦下落后的推送 exit=${behindPush.status}`)
const svnAllowed = runGuard('svn-commit-guard.sh', 'svn commit -m "chore: 测试"', ROOT)
check(svnAllowed.status === 0, `svn 闸门在非工作副本放行 exit=${svnAllowed.status}`)
rmSync(sandbox, { recursive: true, force: true })

console.log(failures === 0 ? `\n${plugins.length} 个插件全部通过` : `\n${failures} 项失败`)
process.exit(failures === 0 ? 0 : 1)
