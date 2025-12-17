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
// TYPE DEFINITIONS
// ============================================================================

/** Struttura del documento che verrà creato */
type DocumentData = {
  id: string;
  name: string;
  fileData: string; // base64 per prototipo, sostituire con URL/path in produzione
  mime: string;
  type: string;
  date: string;
  client: string;
  status: 'attivo' | 'in revisione' | 'scaduto';
  uploadedAt: string;
};

// ============================================================================
// PROPS & STATE
// ============================================================================

/** Callback per notificare l'aggiunta di un documento */
export let onAdd: (doc: DocumentData) => void;

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
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Genera un ID univoco per il documento.
 * NOTA: In produzione usare UUID dal backend.
 */
function genId(): string {
  return `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

/**
 * Converte un file in data URL (base64).
 * 
 * ⚠️ NOTA IMPORTANTE PER PRODUZIONE:
 * Questa funzione è OK solo per prototipi o file piccoli (<5MB).
 * Per produzione, usare FormData e upload streaming al backend.
 * 
 * @see Document index 1 per implementazione corretta con FormData
 */
function toDataURL(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    
    reader.onload = () => {
      const result = reader.result;
      if (typeof result === 'string') {
        resolve(result);
      } else {
        reject(new Error('Errore nella lettura del file'));
      }
    };
    
    reader.onerror = () => {
      reject(new Error('Errore durante la lettura del file'));
    };
    
    reader.readAsDataURL(file);
  });
}

// ============================================================================
// FORM SUBMISSION
// ============================================================================

/**
 * Gestisce l'invio del form.
 * Valida i dati, converte il file e chiama il callback onAdd.
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

    // Converti file in base64 (solo per prototipo!)
    const dataUrl = await toDataURL(file);

    // Crea oggetto documento
    const doc: DocumentData = {
      id: genId(),
      name: file.name,
      fileData: dataUrl,
      mime: file.type,
      type: type.trim(),
      date: date,
      client: client.trim(),
      status: status,
      uploadedAt: new Date().toISOString()
    };

    // Chiama callback del parent
    onAdd(doc);

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

<form on:submit={onSubmit} class="upload-form">
  
  <!-- Messaggio di errore -->
  {#if error}
    <div class="error-message">
      ⚠️ {error}
    </div>
  {/if}

  <!-- Campo File -->
  <div class="form-field">
    <label for="file-input">
      File *
      <span class="help-text">(Max {maxFileSize}MB)</span>
    </label>
    <input 
      id="file-input" 
      type="file" 
      on:change={onFileChange} 
      required 
      disabled={isLoading}
    />
  </div>

  <!-- Campo Tipo -->
  <div class="form-field">
    <label for="type-input">Tipo documento</label>
    <input 
      id="type-input"
      type="text" 
      bind:value={type} 
      placeholder="es. Fattura, Contratto, Preventivo"
      disabled={isLoading}
    />
  </div>

  <!-- Campo Data -->
  <div class="form-field">
    <label for="date-input">Data documento</label>
    <input 
      id="date-input"
      type="date" 
      bind:value={date}
      disabled={isLoading}
    />
  </div>

  <!-- Campo Cliente -->
  <div class="form-field">
    <label for="client-input">Cliente / Progetto</label>
    <input 
      id="client-input"
      type="text" 
      bind:value={client} 
      placeholder="Nome cliente o progetto"
      disabled={isLoading}
    />
  </div>

  <!-- Campo Stato -->
  <div class="form-field">
    <label for="status-select">Stato</label>
    <select 
      id="status-select"
      bind:value={status}
      disabled={isLoading}
    >
      <option value="attivo">Attivo</option>
      <option value="in revisione">In revisione</option>
      <option value="scaduto">Scaduto</option>
    </select>
  </div>

  <!-- Bottone Submit -->
  <div class="submit-wrapper">
    <button 
      type="submit" 
      disabled={isLoading || !file}
      class:loading={isLoading}
    >
      {isLoading ? 'Caricamento...' : 'Carica documento'}
    </button>
  </div>

</form>

<!-- ========================================================================== -->
<!-- STYLES -->
<!-- ========================================================================== -->

<style>
  .upload-form {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.8rem;
    align-items: end;
  }

  .error-message {
    grid-column: 1 / -1;
    padding: 0.6rem;
    background: #fee;
    border: 1px solid #fcc;
    border-radius: 4px;
    color: #c33;
    font-size: 0.9rem;
  }

  .form-field {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .form-field label {
    font-size: 0.85rem;
    font-weight: 500;
    color: #333;
  }

  .help-text {
    font-weight: normal;
    color: #666;
    font-size: 0.8rem;
  }

  .form-field input,
  .form-field select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.9rem;
  }

  .form-field input:focus,
  .form-field select:focus {
    outline: none;
    border-color: #4a90e2;
    box-shadow: 0 0 0 3px rgba(74, 144, 226, 0.1);
  }

  .form-field input:disabled,
  .form-field select:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
  }

  .submit-wrapper {
    grid-column: 1 / -1;
  }

  button[type="submit"] {
    width: 100%;
    padding: 0.7rem;
    background: #4a90e2;
    color: white;
    border: none;
    border-radius: 4px;
    font-weight: 500;
    cursor: pointer;
    transition: background 0.2s;
  }

  button[type="submit"]:hover:not(:disabled) {
    background: #357abd;
  }

  button[type="submit"]:disabled {
    background: #ccc;
    cursor: not-allowed;
  }

  button[type="submit"].loading {
    position: relative;
  }

  button[type="submit"].loading::after {
    content: '⏳';
    margin-left: 0.5rem;
  }

  /* Responsive: mobile */
  @media (max-width: 640px) {
    .upload-form {
      grid-template-columns: 1fr;
    }
  }
</style>