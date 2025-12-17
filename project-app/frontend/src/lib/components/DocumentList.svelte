<script lang="ts">
/**
 * DocumentList.svelte
 * 
 * Componente per visualizzare una lista di documenti.
 * Gestisce stati: empty, loading, error.
 * Pattern Svelte 5: usa callback props per comunicare con il parent.
 * 
 * Props:
 * - documents: array di documenti da visualizzare
 * - onDelete: callback per eliminazione documento
 * - isLoading: indica se i dati stanno caricando (opzionale)
 * - error: messaggio di errore da mostrare (opzionale)
 * - readonly: se true, passa readonly alle card (opzionale)
 */

// ============================================================================
// IMPORTS
// ============================================================================

import DocumentCard from './DocumentCard.svelte';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/** Struttura del documento */
type DocumentData = {
  id: string;
  name: string;
  fileData: string;
  mime?: string;
  type?: string;
  date?: string;
  client?: string;
  status?: 'attivo' | 'in revisione' | 'scaduto';
  uploadedAt?: string;
};

// ============================================================================
// PROPS
// ============================================================================

/** Array di documenti da visualizzare */
export let documents: DocumentData[] = [];

/** Callback per eliminazione documento */
export let onDelete: (id: string) => void;

/** Indica se i dati stanno caricando */
export let isLoading: boolean = false;

/** Messaggio di errore (se presente) */
export let error: string = '';

/** Modalità readonly (disabilita eliminazione) */
export let readonly: boolean = false;

/** Numero massimo di documenti da mostrare (0 = tutti) */
export let limit: number = 0;

// ============================================================================
// COMPUTED PROPERTIES
// ============================================================================

/** Documenti da visualizzare (con limite se specificato) */
$: displayedDocuments = limit > 0 
  ? documents.slice(0, limit)
  : documents;

/** Conta dei documenti nascosti dal limite */
$: hiddenCount = limit > 0 && documents.length > limit
  ? documents.length - limit
  : 0;

/** Flag: lista vuota */
$: isEmpty = documents.length === 0;

// ============================================================================
// HANDLERS
// ============================================================================

/**
 * Gestisce la richiesta di eliminazione da una card.
 * Propaga al parent tramite callback.
 */
function handleDelete(id: string) {
  onDelete(id);
}

</script>

<!-- ========================================================================== -->
<!-- TEMPLATE -->
<!-- ========================================================================== -->
<div class="w-full">

  <!-- ================= LOADING ================= -->
  {#if isLoading}
    <div
      class="
        flex flex-col items-center justify-center
        px-4 py-12 text-center text-gray-600
        max-sm:py-8
      "
    >
      <div
        class="
          mb-4 h-10 w-10 animate-spin
          rounded-full border-4
          border-gray-200 border-t-blue-500
          motion-reduce:animate-none
        "
      ></div>
      <p class="text-sm">Caricamento documenti...</p>
    </div>

  <!-- ================= ERRORE ================= -->
  {:else if error}
    <div
      class="
        flex flex-col items-center justify-center
        px-4 py-12 text-center
        text-red-700 max-sm:py-8
      "
    >
      <div class="mb-2 text-4xl">⚠️</div>
      <p class="mb-2 text-lg font-semibold">
        Si è verificato un errore
      </p>
      <p class="max-w-md text-sm text-gray-600">
        {error}
      </p>
    </div>

  <!-- ================= EMPTY ================= -->
  {:else if isEmpty}
    <div
      class="
        flex flex-col items-center justify-center
        px-4 py-12 text-center
        text-gray-500 max-sm:py-8
      "
    >
      <div class="mb-4 text-6xl opacity-30 max-sm:text-5xl">
        📄
      </div>
      <p class="mb-2 text-lg font-semibold text-gray-600">
        Nessun documento presente
      </p>
      <p class="text-sm text-gray-400">
        Carica il tuo primo documento per iniziare
      </p>
    </div>

  <!-- ================= LISTA ================= -->
  {:else}
    <div class="w-full">

      <!-- Header -->
      <div
        class="
          mb-3 flex items-center justify-between
          px-1 text-sm font-medium text-gray-500
          max-sm:flex-col max-sm:items-start max-sm:gap-2
        "
      >
        <span>
          {documents.length}
          {documents.length === 1 ? ' documento' : ' documenti'}
        </span>
      </div>

      <!-- Cards -->
      <div class="flex flex-col">
        {#each displayedDocuments as doc (doc.id)}
          <DocumentCard
            {doc}
            {readonly}
            onDelete={handleDelete}
          />
        {/each}
      </div>

      <!-- Hidden indicator -->
      {#if hiddenCount > 0}
        <div
          class="
            mt-2 border-t border-dashed border-gray-300
            px-2 py-3 text-center
            text-sm italic text-gray-500
          "
        >
          + altri {hiddenCount}
          {hiddenCount === 1 ? ' documento' : ' documenti'}
        </div>
      {/if}

    </div>
  {/if}

</div>
