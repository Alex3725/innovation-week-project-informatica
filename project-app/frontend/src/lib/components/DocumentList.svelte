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

<div class="document-list">

  <!-- STATO: Loading -->
  {#if isLoading}
    <div class="state-message loading">
      <div class="spinner"></div>
      <p>Caricamento documenti...</p>
    </div>

  <!-- STATO: Errore -->
  {:else if error}
    <div class="state-message error">
      <div class="error-icon">⚠️</div>
      <p class="error-title">Si è verificato un errore</p>
      <p class="error-detail">{error}</p>
    </div>

  <!-- STATO: Lista vuota -->
  {:else if isEmpty}
    <div class="state-message empty">
      <div class="empty-icon">📄</div>
      <p class="empty-title">Nessun documento presente</p>
      <p class="empty-subtitle">
        Carica il tuo primo documento per iniziare
      </p>
    </div>

  <!-- STATO: Lista con documenti -->
  {:else}
    <div class="documents-container">
      
      <!-- Header lista (opzionale, mostra conteggio) -->
      <div class="list-header">
        <span class="document-count">
          {documents.length} {documents.length === 1 ? 'documento' : 'documenti'}
        </span>
      </div>

      <!-- Cards documenti -->
      <div class="cards-wrapper">
        {#each displayedDocuments as doc (doc.id)}
          <DocumentCard 
            {doc} 
            {readonly}
            onDelete={handleDelete}
          />
        {/each}
      </div>

      <!-- Indicatore documenti nascosti -->
      {#if hiddenCount > 0}
        <div class="hidden-indicator">
          + altri {hiddenCount} {hiddenCount === 1 ? 'documento' : 'documenti'}
        </div>
      {/if}

    </div>
  {/if}

</div>

<!-- ========================================================================== -->
<!-- STYLES -->
<!-- ========================================================================== -->

<style>
  .document-list {
    width: 100%;
  }

  /* ===== STATI: Loading, Error, Empty ===== */
  
  .state-message {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem 1rem;
    text-align: center;
  }

  /* Loading state */
  .state-message.loading {
    color: #666;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #4a90e2;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  /* Error state */
  .state-message.error {
    color: #c33;
  }

  .error-icon {
    font-size: 3rem;
    margin-bottom: 0.5rem;
  }

  .error-title {
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
  }

  .error-detail {
    font-size: 0.9rem;
    color: #666;
    max-width: 400px;
  }

  /* Empty state */
  .state-message.empty {
    color: #999;
  }

  .empty-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.3;
  }

  .empty-title {
    font-size: 1.2rem;
    font-weight: 600;
    color: #666;
    margin-bottom: 0.5rem;
  }

  .empty-subtitle {
    font-size: 0.9rem;
    color: #999;
  }

  /* ===== LISTA CON DOCUMENTI ===== */

  .documents-container {
    width: 100%;
  }

  .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.8rem;
    padding: 0 0.2rem;
  }

  .document-count {
    font-size: 0.85rem;
    font-weight: 500;
    color: #666;
  }

  .cards-wrapper {
    display: flex;
    flex-direction: column;
  }

  .hidden-indicator {
    text-align: center;
    padding: 0.8rem;
    color: #666;
    font-size: 0.9rem;
    font-style: italic;
    border-top: 1px dashed #ddd;
    margin-top: 0.5rem;
  }

  /* ===== RESPONSIVE ===== */

  @media (max-width: 640px) {
    .state-message {
      padding: 2rem 1rem;
    }

    .empty-icon {
      font-size: 3rem;
    }

    .list-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }
  }

  /* ===== ACCESSIBILITÀ ===== */

  /* Focus visibile per navigazione tastiera */
  :global(.card:focus-within) {
    outline: 2px solid #4a90e2;
    outline-offset: 2px;
  }

  /* Riduci motion per utenti con preferenze accessibilità */
  @media (prefers-reduced-motion: reduce) {
    .spinner {
      animation: none;
      border-top-color: #666;
    }
  }
</style>