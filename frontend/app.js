const form = document.querySelector('#note-form');
const input = document.querySelector('#note-text');
const button = document.querySelector('#submit-button');
const list = document.querySelector('#notes');
const empty = document.querySelector('#empty');
const message = document.querySelector('#message');
const count = document.querySelector('#note-count');
const counter = document.querySelector('#counter');
const status = document.querySelector('#status');

function showMessage(text, isError = false) {
  message.textContent = text;
  message.classList.toggle('error', isError);
}

function renderNotes(notes) {
  list.replaceChildren();
  count.textContent = String(notes.length);
  empty.hidden = notes.length > 0;

  for (const note of notes) {
    const item = document.createElement('li');
    const body = document.createElement('p');
    const time = document.createElement('time');
    body.textContent = note.text;
    time.dateTime = note.createdAt;
    time.textContent = new Intl.DateTimeFormat('ru-RU', {
      dateStyle: 'medium', timeStyle: 'short'
    }).format(new Date(note.createdAt));
    item.append(body, time);
    list.append(item);
  }
}

async function loadNotes() {
  const response = await fetch('/api/notes');
  if (!response.ok) throw new Error(`API ответил ${response.status}`);
  const data = await response.json();
  renderNotes(data.response);
  const instance = response.headers.get('X-Backend-Instance');
  status.textContent = instance ? `API работает · ${instance}` : 'API работает';
  status.classList.add('online');
}

input.addEventListener('input', () => {
  counter.textContent = `${input.value.length} / 280`;
});

form.addEventListener('submit', async event => {
  event.preventDefault();
  const text = input.value.trim();
  if (!text) return showMessage('Напишите текст заметки.', true);

  button.disabled = true;
  showMessage('Сохраняем…');
  try {
    const response = await fetch('/api/notes/add', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text })
    });
    if (!response.ok) throw new Error(`API ответил ${response.status}`);
    input.value = '';
    counter.textContent = '0 / 280';
    await loadNotes();
    showMessage('Заметка сохранена в MongoDB.');
  } catch (error) {
    showMessage(`Не удалось сохранить заметку: ${error.message}`, true);
  } finally {
    button.disabled = false;
  }
});

loadNotes().catch(error => {
  status.textContent = 'Нет соединения с API';
  showMessage(`Не удалось загрузить заметки: ${error.message}`, true);
});
