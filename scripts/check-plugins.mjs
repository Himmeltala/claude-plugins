/*
 * @Author: Himmeltala
 * @Date: 2026-10-29 16:02:00
 * @LastEditors: Himmeltala
 * @LastEditTime: 2026-11-06 16:00:00
 * @FilePath: \scripts\check-plugins.mjs
 * @Description: 校验八个插件的 Claude 打包：清单与目录一致、技能可列出、提交闸门脚本可拦可放。
 */
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'
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

// 提交闸门：把 payload 喂给两份钩子脚本，带范围括号的提交要拦下，普通命令要放行。
const guardDir = join(ROOT, 'plugins', 'commit-guarding', 'hooks', 'scripts')
const payload = (command) => JSON.stringify({
  session_id: 'check',
  hook_event_name: 'PreToolUse',
  tool_name: 'Bash',
  cwd: ROOT,
  tool_input: { command },
})
const runGuard = (script, command) =>
  spawnSync('bash', [join(guardDir, script)], { input: payload(command), encoding: 'utf8' })

const denied = runGuard('git-commit-guard.sh', 'git commit -m "feat(login): 加个功能"')
check(denied.status === 2, `git 闸门拦下带范围括号的提交 exit=${denied.status}`)
const allowed = runGuard('git-commit-guard.sh', 'ls -la')
check(allowed.status === 0, `git 闸门放行普通命令 exit=${allowed.status}`)
const svnDenied = runGuard('svn-commit-guard.sh', 'svn commit -m "feat(login): 加个功能"')
check(svnDenied.status === 2, `svn 闸门拦下带范围括号的提交 exit=${svnDenied.status}`)

console.log(failures === 0 ? `\n${plugins.length} 个插件全部通过` : `\n${failures} 项失败`)
process.exit(failures === 0 ? 0 : 1)
