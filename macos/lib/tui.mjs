// Interactive terminal menu (mirrors Invoke-TuiMode ps1:2425, expanded to the
// macOS core feature set).
import readline from 'node:readline';
import { APP_VERSION } from './platform.mjs';
import { t, setLang, getLang, langCycle } from './i18n.mjs';
import { showEnv, scanAgents, configureAgents, copyMcp } from './actions.mjs';
import { installAll } from './install.mjs';
import { startService, stopService, openViewer } from './service.mjs';

function ask(rl, question) {
  return new Promise((resolve) => rl.question(question, (answer) => resolve(answer)));
}

function printMenu() {
  console.log('');
  console.log(`  ${t('Title')}  (v${APP_VERSION})`);
  console.log('  ' + '-'.repeat(40));
  console.log(`  1. ${t('MenuEnv')}`);
  console.log(`  2. ${t('MenuInstall')}`);
  console.log(`  3. ${t('MenuStart')}`);
  console.log(`  4. ${t('MenuStop')}`);
  console.log(`  5. ${t('MenuConfigure')}`);
  console.log(`  6. ${t('MenuScan')}`);
  console.log(`  7. ${t('MenuCopyMcp')}`);
  console.log(`  8. ${t('MenuViewer')}`);
  console.log(`  9. ${t('MenuLang')}`);
  console.log(`  0. ${t('MenuExit')}`);
  console.log('');
}

export async function runTui() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let running = true;
    while (running) {
      printMenu();
      const choice = (await ask(rl, `${t('Select')} > `)).trim();
      console.log('');
      switch (choice) {
        case '1':
          await showEnv();
          break;
        case '2':
          await installAll();
          break;
        case '3':
          await startService();
          break;
        case '4':
          await stopService();
          break;
        case '5':
          configureAgents();
          break;
        case '6':
          scanAgents();
          break;
        case '7':
          copyMcp();
          break;
        case '8':
          await openViewer();
          break;
        case '9': {
          setLang(langCycle());
          console.log(t('LangSwitched'));
          break;
        }
        case '0':
          running = false;
          break;
        default:
          console.log(t('UnknownChoice'));
      }
      if (running && choice !== '9') {
        await ask(rl, `\n${t('PressEnter')}`);
      }
    }
  } finally {
    rl.close();
  }
  return 0;
}

// Allow the TUI to start in a non-default language (e.g. from an env var).
export function initLangFromEnv() {
  const env = process.env.CAC_LANG;
  if (env && ['zh', 'en', 'zh-TW'].includes(env)) setLang(env);
  return getLang();
}
