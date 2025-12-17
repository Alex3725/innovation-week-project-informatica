<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();
  export let initialSearch = '';
  export let initialType = '';
  export let initialStatus = '';

  let search = initialSearch;
  let type = initialType;
  let status = initialStatus;

  function apply() {
    dispatch('filter', { search, type, status });
  }

  function reset() {
    search = ''; type = ''; status = '';
    apply();
  }
</script>

<div class="filters">
  <input placeholder="Cerca parole chiave..." bind:value={search} on:input={apply} />
  <input placeholder="Tipo" bind:value={type} on:input={apply} />
  <select bind:value={status} on:change={apply}>
    <option value="">Tutti gli stati</option>
    <option value="attivo">attivo</option>
    <option value="in revisione">in revisione</option>
    <option value="scaduto">scaduto</option>
  </select>
  <button on:click={reset}>Reset</button>
</div>

<style>
.filters{display:flex;gap:0.5rem;margin-bottom:0.8rem}
.filters input{flex:1;padding:0.4rem}
.filters select{padding:0.4rem}
.filters button{padding:0.4rem}
</style>
