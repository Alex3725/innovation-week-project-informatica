<script lang="ts">
  import DocumentCard from './DocumentCard.svelte';
  export let documents: any[] = [];
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();

  function onDelete(id:string){
    dispatch('delete', id);
  }
</script>

  {#if documents.length === 0}
    <p>Nessun documento caricato.</p>
  {:else}
    <div>
      {#each documents as doc (doc.id)}
        <DocumentCard {doc} on:delete={(e)=>onDelete(e.detail)} />
      {/each}
    </div>
  {/if}

<style>
  p{color:#666}
</style>
