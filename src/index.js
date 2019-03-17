import './main.css';
import {Elm} from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const checklists = localStorage.getItem('checklists') || '[]';

console.log('Loaded: ', checklists);

let parsedChecklists = [];
try {
  parsedChecklists = JSON.parse(checklists);
} catch (error) {
  console.log('Failed to decode local storage value: ', checklists);
}

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {checklists: parsedChecklists},
});

app.ports.outPort.subscribe(message => {
  switch (message.type) {
    case 'save':
      console.log('Saving: ', JSON.stringify(message.data, null, 2));
      localStorage.setItem('checklists', JSON.stringify(message.data));
      break;
    default:
      console.log(`Unrecognised message: ${message.type}`);
  }
});

registerServiceWorker();
