<script lang="ts">
/**
 * UploadForm.svelte
 * 
 * Componente per il caricamento di documenti con metadati.
 * Pattern Svelte 5: usa callback props invece di createEventDispatcher.
 * 
 * Props:
 * - onAdd: callback chiamata quando un documento viene aggiunto con successo
 * - maxFileSize: dimensione massima file in MB (default: 10MB)
 * - allowedTypes: array di MIME types consentiti (default: tutti)
 */

// ============================================================================
// PROPS & STATE
// ============================================================================

/** Callback per notificare l'aggiunta di un documento */
export let onAdd: (file: File, metadata: { type: string; date: string; client: string; status: 'attivo' | 'in revisione' | 'scaduto'; }) => void;

/** Dimensione massima file in MB */
export let maxFileSize: number = 10;

/** MIME types consentiti (vuoto = tutti) */
export let allowedTypes: string[] = [];

// State del form
let file: File | null = null;
let type = '';
let date = '';
let client = '';
let status: 'attivo' | 'in revisione' | 'scaduto' = 'attivo';

// State per errori e loading
let error: string = '';
let isLoading: boolean = false;

// ============================================================================
// FILE HANDLING
// ============================================================================

/**
 * Gestisce la selezione del file dall'input.
 * Valida dimensione e tipo prima di accettare il file.
 */
function onFileChange(e: Event) {
  // Reset errore precedente
  error = '';
  
  const input = e.target as HTMLInputElement;
  const selectedFile = input.files?.[0] || null;
  
  if (!selectedFile) {
    file = null;
    return;
  }

  // VALIDAZIONE 1: Dimensione file
  const maxBytes = maxFileSize * 1024 * 1024;
  if (selectedFile.size > maxBytes) {
    error = `File troppo grande. Massimo ${maxFileSize}MB consentiti.`;
    input.value = ''; // Reset input
    file = null;
    return;
  }

  // VALIDAZIONE 2: Tipo file (se specificato)
  if (allowedTypes.length > 0 && !allowedTypes.includes(selectedFile.type)) {
    error = `Tipo file non consentito. Formati accettati: ${allowedTypes.join(', ')}`;
    input.value = '';
    file = null;
    return;
  }

  file = selectedFile;
}

// ============================================================================
// FORM SUBMISSION
// ============================================================================

/**
 * Gestisce l'invio del form.
 * Valida i dati, e chiama il callback onAdd.
 */
async function onSubmit(e: Event) {
  e.preventDefault();
  
  // Reset errore
  error = '';
  
  // VALIDAZIONE: File obbligatorio
  if (!file) {
    error = 'Seleziona un file da caricare';
    return;
  }

  try {
    isLoading = true;

    // Chiama callback del parent
    await onAdd(file, {
      type: type.trim(),
      date: date,
      client: client.trim(),
      status: status,
    });

    // Reset form dopo successo
    resetForm();

  } catch (err) {
    // Gestione errori durante l'upload
    console.error('Errore durante l\'upload:', err);
    error = err instanceof Error 
      ? `Errore: ${err.message}` 
      : 'Errore sconosciuto durante l\'upload';
  } finally {
    isLoading = false;
  }
}

/**
 * Resetta tutti i campi del form allo stato iniziale.
 */
function resetForm() {
  file = null;
  type = '';
  date = '';
  client = '';
  status = 'attivo';
  error = '';

  // Reset input file
  const input = document.getElementById('file-input') as HTMLInputElement | null;
  if (input) input.value = '';
}

</script>

<!-- ========================================================================== -->
<!-- TEMPLATE -->
<!-- ========================================================================== -->

<form
  on:submit={onSubmit}
  class="
    grid grid-cols-2 gap-3 items-end
    max-sm:grid-cols-1
  "
>
  <!-- ================= ERRORE ================= -->
  {#if error}
    <div
      class="
        col-span-full
        rounded border border-red-300 bg-red-50
        px-3 py-2 text-sm text-red-700
      "
    >
      ⚠️ {error}
    </div>
  {/if}

  <!-- ================= FILE ================= -->
  <div class="flex flex-col gap-1">
    <label for="file-input" class="text-sm font-medium text-gray-800">
      File *
      <span class="ml-1 text-xs font-normal text-gray-500">
        (Max {maxFileSize}MB)
      </span>
    </label>

    <input
      id="file-input"
      type="file"
      on:change={onFileChange}
      required
      disabled={isLoading}
      class="
        w-full rounded border border-gray-300
        px-2 py-2 text-sm
        file:mr-3 file:rounded file:border-0
        file:bg-gray-100 file:px-3 file:py-1.5
        file:text-sm file:font-medium
        hover:file:bg-gray-200
        focus:outline-none focus:ring-2 focus:ring-blue-200
        disabled:cursor-not-allowed disabled:bg-gray-100
      "
    />
  </div>

  <!-- ================= TIPO ================= -->
  <div class="flex flex-col gap-1">
    <label for="type-input" class="text-sm font-medium text-gray-800">
      Tipo documento
    </label>

    <input
      id="type-input"
      type="text"
      bind:value={type}
      placeholder="es. Fattura, Contratto, Preventivo"
      disabled={isLoading}
      class="
        w-full rounded border border-gray-300
        px-2 py-2 text-sm
        focus:outline-none focus:ring-2 focus:ring-blue-200
        disabled:cursor-not-allowed disabled:bg-gray-100
      "
    />
  </div>

  <!-- ================= DATA ================= -->
  <div class="flex flex-col gap-1">
    <label for="date-input" class="text-sm font-medium text-gray-800">
      Data documento
    </label>

    <input
      id="date-input"
      type="date"
      bind:value={date}
      disabled={isLoading}
      class="
        w-full rounded border border-gray-300
        px-2 py-2 text-sm
        focus:outline-none focus:ring-2 focus:ring-blue-200
        disabled:cursor-not-allowed disabled:bg-gray-100
      "
    />
  </div>

  <!-- ================= CLIENTE ================= -->
  <div class="flex flex-col gap-1">
    <label for="client-input" class="text-sm font-medium text-gray-800">
      Cliente / Progetto
    </label>

    <input
      id="client-input"
      type="text"
      bind:value={client}
      placeholder="Nome cliente o progetto"
      disabled={isLoading}
      class="
        w-full rounded border border-gray-300
        px-2 py-2 text-sm
        focus:outline-none focus:ring-2 focus:ring-blue-200
        disabled:cursor-not-allowed disabled:bg-gray-100
      "
    />
  </div>

  <!-- ================= STATO ================= -->
  <div class="flex flex-col gap-1">
    <label for="status-select" class="text-sm font-medium text-gray-800">
      Stato
    </label>

    <select
      id="status-select"
      bind:value={status}
      disabled={isLoading}
      class="
        w-full rounded border border-gray-300
        px-2 py-2 text-sm
        focus:outline-none focus:ring-2 focus:ring-blue-200
        disabled:cursor-not-allowed disabled:bg-gray-100
      "
    >
      <option value="attivo">Attivo</option>
      <option value="in revisione">In revisione</option>
      <option value="scaduto">Scaduto</option>
    </select>
  </div>

  <!-- ================= SUBMIT ================= -->
  <div class="col-span-full">
    <button
      type="submit"
      disabled={isLoading || !file}
      class="
        w-full rounded bg-blue-500 px-4 py-3
        text-sm font-medium text-white
        transition
        hover:bg-blue-600
        disabled:cursor-not-allowed disabled:bg-gray-400
        flex items-center justify-center gap-2
      "
    >
      {isLoading ? 'Caricamento...' : 'Carica documento'}
      {#if isLoading}
        <span>⏳</span>
      {/if}
    </button>
  </div>
</form>
