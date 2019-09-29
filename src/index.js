import './main.css';
import {Elm} from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

function attemptParseData(string) {
  try {
    const parsed = JSON.parse(string);
    return parsed;
  } catch (error) {
    console.log('Failed to JSON.parse value: ', string);
  }
  return null;
}

function main() {
  const data = localStorage.getItem('data');
  let parsedData = data !== null ? attemptParseData(data) : null;

  if (parsedData === null) {
    const checklists = localStorage.getItem('checklists');
    console.log({checklists});
    const parsedChecklists =
      checklists !== null ? attemptParseData(checklists) : null;
    console.log({parsedChecklists});
    if (parsedChecklists !== null) {
      parsedData = {version: 1, checklists: parsedChecklists};
    } else {
      parsedData = {version: 1, checklists: []};
    }
  }

  console.log('Loaded: ', parsedData);

  const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {data: parsedData, time: new Date().getTime()},
  });

  app.ports.outPort.subscribe(message => {
    switch (message.type) {
      case 'save':
        console.log('Saving: ', JSON.stringify(message.data, null, 2));
        localStorage.setItem('data', JSON.stringify(message.data));
        break;
      default:
        console.log(`Unrecognised message: ${message.type}`);
    }
  });
}

main();

registerServiceWorker();
