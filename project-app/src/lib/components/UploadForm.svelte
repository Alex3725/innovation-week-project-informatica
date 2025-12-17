<script lang="ts">
import { createEventDispatcher } from 'svelte';

const dispatch = createEventDispatcher();

let file: File | null = null;
let type = '';
let date = '';
let client = '';
let status = 'attivo';

function onFileChange(e: Event) {
  const input = e.target as HTMLInputElement;
  file = input.files && input.files[0] ? input.files[0] : null;
}

function genId() {
  return `${Date.now()}-${Math.floor(Math.random()*100000)}`;
}

function toDataURL(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

async function onSubmit(e: Event) {
  e.preventDefault();
  if (!file) return;
  const dataUrl = await toDataURL(file);
  const doc = {
    id: genId(),
    name: file.name,
    fileData: dataUrl,
    mime: file.type,
    type,
    date,
    client,
    status,
    uploadedAt: new Date().toISOString()
  };
  dispatch('add', doc);
  // reset
  file = null; type = ''; date = ''; client = ''; status = 'attivo';
  const input = document.getElementById('file-input') as HTMLInputElement | null;
  if (input) input.value = '';
}
</script>

<form on:submit|preventDefault={onSubmit} class="upload-form">
  <div>
    <label>File</label>
    <input id="file-input" type="file" on:change={onFileChange} required />
  </div>
  <div>
    <label>Tipo</label>
    <input type="text" bind:value={type} placeholder="es. Fattura, Contratto" />
  </div>
  <div>
    <label>Data (YYYY-MM-DD)</label>
    <input type="date" bind:value={date} />
  </div>
  <div>
    <label>Cliente / Progetto</label>
    <input type="text" bind:value={client} placeholder="Cliente XYZ" />
  </div>
  <div>
    <label>Stato</label>
    <select bind:value={status}>
      <option value="attivo">attivo</option>
      <option value="in revisione">in revisione</option>
      <option value="scaduto">scaduto</option>
    </select>
  </div>
  <div>
    <button type="submit">Carica documento</button>
  </div>
</form>

<style>
.upload-form{display:grid;grid-template-columns:1fr 1fr;gap:0.6rem;align-items:end}
.upload-form label{display:block;font-size:0.85rem;color:#333}
.upload-form input,.upload-form select{width:100%;padding:0.35rem}
.upload-form button{grid-column:1/-1;padding:0.6rem}
</style>
