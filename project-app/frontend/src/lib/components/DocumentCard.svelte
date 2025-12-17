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

<div
  class="
    relative mb-2 flex items-center justify-between gap-4
    rounded-md border border-gray-200 bg-white p-3
    transition-all duration-200
    hover:border-gray-400 hover:shadow-sm
  "
  class:border-red-300={isExpired}
  class:bg-red-50={isExpired}
>
  <!-- ================= METADATI ================= -->
  <div class="flex min-w-0 flex-1 flex-col gap-1">
    <div
      class="truncate text-sm font-semibold text-gray-900"
      title={doc.name}
    >
      {doc.name}
    </div>

    {#if metadataInfo}
      <div class="text-sm text-gray-500">
        {metadataInfo}
      </div>
    {/if}

    {#if doc.status}
      <span
        class="
          w-fit rounded-full px-2 py-0.5
          text-xs font-medium
        "
        class:bg-green-100={doc.status === 'attivo'}
        class:text-green-800={doc.status === 'attivo'}
        class:bg-yellow-100={doc.status === 'in revisione'}
        class:text-yellow-800={doc.status === 'in revisione'}
        class:bg-red-100={doc.status === 'scaduto'}
        class:text-red-800={doc.status === 'scaduto'}
      >
        {doc.status}
      </span>
    {/if}
  </div>

  <!-- ================= AZIONI ================= -->
  <div class="flex shrink-0 gap-2 max-sm:w-full max-sm:justify-between">
    <button
      class="
        rounded border border-gray-300 bg-white
        px-2.5 py-1.5 text-sm
        transition
        hover:border-blue-400 hover:bg-blue-50
        disabled:cursor-not-allowed disabled:opacity-50
      "
      on:click={view}
      disabled={isProcessing}
      title="Visualizza documento"
    >
      👁️ Vedi
    </button>

    <button
      class="
        rounded border border-gray-300 bg-white
        px-2.5 py-1.5 text-sm
        transition
        hover:border-green-400 hover:bg-green-50
        disabled:cursor-not-allowed disabled:opacity-50
      "
      on:click={download}
      disabled={isProcessing}
      title="Scarica documento"
    >
      ⬇️ Scarica
    </button>

    {#if !readonly}
      <button
        class="
          rounded border border-gray-300 bg-white
          px-2.5 py-1.5 text-sm text-red-600
          transition
          hover:border-red-400 hover:bg-red-50
          disabled:cursor-not-allowed disabled:opacity-50
        "
        on:click={remove}
        disabled={isProcessing}
        title="Elimina documento"
      >
        🗑️ Elimina
      </button>
    {/if}
  </div>

  <!-- ================= ERRORE ================= -->
  {#if error}
    <div
      class="
        absolute -bottom-6 left-0 right-0
        rounded bg-red-100 px-2 py-1
        text-xs text-red-700
      "
    >
      ⚠️ {error}
    </div>
  {/if}
</div>
