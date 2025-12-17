<script lang="ts">
/**
 * DocumentCard.svelte
 * 
 * Componente per visualizzare un singolo documento nella lista.
 * Fornisce azioni per: visualizzare, scaricare ed eliminare.
 * Pattern Svelte 5: usa callback props invece di eventi custom.
 * 
 * Props:
 * - doc: dati del documento da visualizzare
 * - onDelete: callback chiamata quando si richiede l'eliminazione
 * - readonly: se true, nasconde il pulsante elimina (opzionale)
 */

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/** Struttura del documento visualizzato */
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

/** Dati del documento da visualizzare */
export let doc: DocumentData;

/** Callback per eliminazione documento */
export let onDelete: (id: string) => void;

/** Modalità readonly (nasconde elimina) */
export let readonly: boolean = false;

// ============================================================================
// STATE
// ============================================================================

/** Indica se un'azione è in corso (per disabilitare pulsanti) */
let isProcessing: boolean = false;

/** Messaggio di errore se un'operazione fallisce */
let error: string = '';

// ============================================================================
// ACTIONS HANDLERS
// ============================================================================

/**
 * Apre il documento in una nuova tab del browser.
 * 
 * ⚠️ NOTA PRODUZIONE:
 * Con base64 questo funziona, ma per file da backend
 * usare URL firmati con scadenza (pre-signed URLs).
 */
function view() {
  try {
    isProcessing = true;
    error = '';

    // Validazione: verifica che ci sia effettivamente il file
    if (!doc.fileData) {
      error = 'Dati del file non disponibili';
      return;
    }

    // Apri in nuova finestra
    const newWindow = window.open();
    
    if (!newWindow) {
      // Popup bloccato dal browser
      error = 'Popup bloccato. Abilita i popup per visualizzare il documento.';
      return;
    }

    newWindow.location.href = doc.fileData;

  } catch (err) {
    console.error('Errore durante la visualizzazione:', err);
    error = 'Errore durante l\'apertura del documento';
  } finally {
    isProcessing = false;
  }
}

/**
 * Scarica il documento sul dispositivo dell'utente.
 * 
 * ⚠️ NOTA PRODUZIONE:
 * Per backend, usare endpoint dedicato che restituisce il file
 * con header appropriati (Content-Disposition, Content-Type).
 */
function download() {
  try {
    isProcessing = true;
    error = '';

    // Validazione
    if (!doc.fileData || !doc.name) {
      error = 'Dati del file non validi';
      return;
    }

    // Crea elemento <a> temporaneo per il download
    const a = document.createElement('a');
    a.href = doc.fileData;
    a.download = doc.name;
    
    // Aggiungi al DOM, clicca, rimuovi
    document.body.appendChild(a);
    a.click();
    
    // Cleanup: rimuovi elemento dopo un breve delay
    setTimeout(() => {
      document.body.removeChild(a);
    }, 100);

  } catch (err) {
    console.error('Errore durante il download:', err);
    error = 'Errore durante il download del documento';
  } finally {
    isProcessing = false;
  }
}

/**
 * Richiede la conferma ed elimina il documento.
 * Chiama il callback onDelete del parent.
 */
function remove() {
  // Conferma dall'utente
  const confirmed = confirm(
    `Sei sicuro di voler eliminare "${doc.name}"?\nQuesta azione non può essere annullata.`
  );

  if (!confirmed) return;

  try {
    isProcessing = true;
    error = '';

    // Chiama callback parent
    onDelete(doc.id);

  } catch (err) {
    console.error('Errore durante l\'eliminazione:', err);
    error = 'Errore durante l\'eliminazione del documento';
  } finally {
    isProcessing = false;
  }
}

// ============================================================================
// COMPUTED PROPERTIES
// ============================================================================

/** Determina se il documento è scaduto per lo stile visuale */
$: isExpired = doc.status === 'scaduto';

/** Formatta la data in formato leggibile */
$: formattedDate = doc.date 
  ? new Date(doc.date).toLocaleDateString('it-IT', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    })
  : 'Data non disponibile';

/** Info metadata concatenate per display */
$: metadataInfo = [
  doc.type,
  doc.client,
  formattedDate
].filter(Boolean).join(' • ');

</script>

<!-- ========================================================================== -->
<!-- TEMPLATE -->
<!-- ========================================================================== -->

<div class="card" class:expired={isExpired}>
  
  <!-- Colonna Metadati -->
  <div class="meta">
    <div class="document-name">
      {doc.name}
    </div>
    
    {#if metadataInfo}
      <div class="metadata">
        {metadataInfo}
      </div>
    {/if}

    {#if doc.status}
      <div class="status-badge" data-status={doc.status}>
        {doc.status}
      </div>
    {/if}
  </div>

  <!-- Colonna Azioni -->
  <div class="actions">
    <button 
      class="action-btn view-btn"
      on:click={view}
      disabled={isProcessing}
      title="Visualizza documento"
    >
      👁️ Vedi
    </button>

    <button 
      class="action-btn download-btn"
      on:click={download}
      disabled={isProcessing}
      title="Scarica documento"
    >
      ⬇️ Scarica
    </button>

    {#if !readonly}
      <button 
        class="action-btn delete-btn"
        on:click={remove}
        disabled={isProcessing}
        title="Elimina documento"
      >
        🗑️ Elimina
      </button>
    {/if}
  </div>

  <!-- Messaggio errore (se presente) -->
  {#if error}
    <div class="error-inline">
      ⚠️ {error}
    </div>
  {/if}

</div>

<!-- ========================================================================== -->
<!-- STYLES -->
<!-- ========================================================================== -->

<style>
  .card {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    padding: 0.8rem;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    margin-bottom: 0.6rem;
    background: white;
    transition: all 0.2s ease;
    position: relative;
  }

  .card:hover {
    border-color: #bbb;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }

  /* Stile per documenti scaduti */
  .card.expired {
    border-color: #e07a7a;
    background: #fff6f6;
  }

  .card.expired:hover {
    border-color: #c55;
  }

  /* Colonna Metadati */
  .meta {
    flex: 1;
    min-width: 0; /* Permette troncamento testo */
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .document-name {
    font-weight: 600;
    font-size: 0.95rem;
    color: #222;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .metadata {
    font-size: 0.85rem;
    color: #666;
  }

  .status-badge {
    display: inline-block;
    padding: 0.15rem 0.5rem;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 500;
    width: fit-content;
  }

  .status-badge[data-status="attivo"] {
    background: #d4edda;
    color: #155724;
  }

  .status-badge[data-status="in revisione"] {
    background: #fff3cd;
    color: #856404;
  }

  .status-badge[data-status="scaduto"] {
    background: #f8d7da;
    color: #721c24;
  }

  /* Colonna Azioni */
  .actions {
    display: flex;
    gap: 0.4rem;
    flex-shrink: 0;
  }

  .action-btn {
    padding: 0.4rem 0.6rem;
    font-size: 0.85rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
    white-space: nowrap;
  }

  .action-btn:hover:not(:disabled) {
    background: #f5f5f5;
    border-color: #bbb;
  }

  .action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .view-btn:hover:not(:disabled) {
    background: #e3f2fd;
    border-color: #64b5f6;
  }

  .download-btn:hover:not(:disabled) {
    background: #e8f5e9;
    border-color: #81c784;
  }

  .delete-btn {
    color: #c33;
  }

  .delete-btn:hover:not(:disabled) {
    background: #ffebee;
    border-color: #e57373;
  }

  /* Messaggio errore inline */
  .error-inline {
    position: absolute;
    bottom: -1.5rem;
    left: 0;
    right: 0;
    font-size: 0.8rem;
    color: #c33;
    padding: 0.2rem 0.5rem;
    background: #fee;
    border-radius: 4px;
  }

  /* Responsive: mobile */
  @media (max-width: 640px) {
    .card {
      flex-direction: column;
      align-items: flex-start;
    }

    .actions {
      width: 100%;
      justify-content: space-between;
    }

    .action-btn {
      flex: 1;
    }
  }
</style>