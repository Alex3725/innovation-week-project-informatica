<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  export let doc: any;
  const dispatch = createEventDispatcher();

  function view() {
    // open data URL in new tab
    const w = window.open();
    if (w) w.location.href = doc.fileData;
  }

  function download() {
    const a = document.createElement('a');
    a.href = doc.fileData;
    a.download = doc.name;
    document.body.appendChild(a);
    a.click();
    a.remove();
  }

  function remove() {
    dispatch('delete', doc.id);
  }
</script>

<div class="card {doc.status === 'scaduto' ? 'expired' : ''}">
  <div class="meta">
    <strong>{doc.name}</strong>
    <div class="small">{doc.type} — {doc.client} — {doc.date}</div>
  </div>
  <div class="actions">
    <button on:click={view}>Vedi</button>
    <button on:click={download}>Scarica</button>
    <button on:click={remove}>Elimina</button>
  </div>
</div>

<style>
.card{display:flex;justify-content:space-between;align-items:center;padding:0.6rem;border:1px solid #e0e0e0;border-radius:6px;margin-bottom:0.5rem}
.card.expired{border-color:#e07a7a;background:#fff6f6}
.meta .small{font-size:0.85rem;color:#666}
.actions button{margin-left:0.4rem}
</style>
