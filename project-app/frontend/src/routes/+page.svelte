<script lang="ts">
/**
 * +page.svelte
 * 
 * Pagina principale dell'applicazione archivio documenti.
 * Gestisce lo state globale dei documenti e coordina i componenti.
 * 
 * FEATURES:
 * - Upload documenti con metadati
 * - Visualizzazione lista documenti
 * - Filtri e ricerca
 * - Persistenza locale (localStorage per prototipo)
 * - Auto-scadenza documenti basata su data
 * 
 * NOTA PRODUZIONE:
 * - Sostituire localStorage con API backend
 * - Implementare autenticazione/autorizzazione
 * - Usare state management (es. Svelte stores) per app più grandi
 */

// ============================================================================
// IMPORTS
// ============================================================================

import { onMount } from 'svelte';
import { UploadForm, DocumentList, Filters } from '../lib';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/** Struttura completa del documento */
type Doc = {
	id: string;
	name: string;
	fileData?: string;
	mime?: string;
	type?: string;
	date?: string;
	client?: string;
	status?: 'attivo' | 'in revisione' | 'scaduto';
	uploadedAt?: string;
};

/** Struttura dei filtri */
type FilterValues = {
	search: string;
	type: string;
	status: '' | 'attivo' | 'in revisione' | 'scaduto';
};

// ============================================================================
// STATE
// ============================================================================

/** Lista completa dei documenti */
let documents: Doc[] = [];

/** Lista filtrata visualizzata */
let filtered: Doc[] = [];

/** Filtri correnti */
let filters: FilterValues = { 
	search: '', 
	type: '', 
	status: '' 
};

/** Chiave per localStorage (prototipo) */
const STORAGE_KEY = 'docs-proto';

/** Flag: indica se c'è un errore nel caricamento */
let loadingError: string = '';

/** Flag: indica se i dati stanno caricando */
let isLoading: boolean = true;

// ============================================================================
// LIFECYCLE
// ============================================================================

/**
 * Carica i documenti dal localStorage all'avvio.
 * In produzione: sostituire con chiamata API.
 */
onMount(() => {
	try {
		isLoading = true;
		const raw = localStorage.getItem(STORAGE_KEY);
		documents = raw ? JSON.parse(raw) : [];
		
		// Verifica scadenze all'avvio
		checkExpirations();
		
		// Applica filtri iniziali
		applyFilters();
		
	} catch (err) {
		console.error('Errore caricamento documenti:', err);
		loadingError = 'Impossibile caricare i documenti salvati';
		documents = [];
		filtered = [];
	} finally {
		isLoading = false;
	}
});

// ============================================================================
// STORAGE & PERSISTENCE
// ============================================================================

/**
 * Salva i documenti nel localStorage e riapplica i filtri.
 * 
 * NOTA PRODUZIONE:
 * Sostituire con chiamata API POST/PUT al backend.
 * Gestire response, errori, ottimistic updates.
 */
function save() {
	try {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(documents));
		applyFilters();
	} catch (err) {
		console.error('Errore salvataggio:', err);
		// In produzione: mostrare toast/notifica errore
		alert('Errore nel salvataggio dei dati');
	}
}

// ============================================================================
// DOCUMENT MANAGEMENT
// ============================================================================

/**
 * Genera un ID univoco per il documento.
 * NOTA: In produzione usare UUID dal backend.
 */
function genId(): string {
  return `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

/**
 * Aggiunge un nuovo documento alla lista.
 * Callback chiamata da UploadForm.
 */
async function addDocument(file: File, metadata: { type: string; date: string; client: string; status: 'attivo' | 'in revisione' | 'scaduto'; }) {
	const formData = new FormData();
	formData.append('file', file);

	try {
		const response = await fetch('http://127.0.0.1:5000/extract', {
			method: 'POST',
			body: formData,
		});

		if (!response.ok) {
			const errorData = await response.json();
			throw new Error(errorData.error || 'Errore del server');
		}

		const result = await response.json();
		const extracted = JSON.parse(result.extracted_features);

		const newDoc: Doc = {
			id: genId(),
			name: file.name,
			mime: file.type,
			type: extracted.type || metadata.type,
			date: extracted.date || metadata.date,
			client: metadata.client,
			status: metadata.status,
			uploadedAt: new Date().toISOString(),
		};

		documents = [newDoc, ...documents];
		save();

		console.log('Documento aggiunto:', newDoc.name);
	} catch (err) {
		console.error('Errore durante l\'aggiunta del documento:', err);
		alert('Errore durante l\'aggiunta del documento: ' + (err as Error).message);
	}
}


/**
 * Elimina un documento dalla lista.
 * Callback chiamata da DocumentList/DocumentCard.
 */
function deleteDocument(id: string) {
	const docToDelete = documents.find(d => d.id === id);
	
	if (!docToDelete) {
		console.warn('Documento non trovato:', id);
		return;
	}

	// Rimuovi dalla lista
	documents = documents.filter(d => d.id !== id);
	save();
	
	// Log per debug
	console.log('Documento eliminato:', docToDelete.name);
	
	// NOTA PRODUZIONE:
	// Chiamare API DELETE al backend
	// Gestire errori e rollback in caso di failure
}

// ============================================================================
// FILTERS & SEARCH
// ============================================================================

/**
 * Applica i filtri correnti alla lista documenti.
 * Filtra per: testo di ricerca, tipo e stato.
 */
function applyFilters() {
	filtered = documents.filter(doc => {
		// Testo completo per ricerca (case-insensitive)
		const searchText = `${doc.name} ${doc.type || ''} ${doc.client || ''} ${doc.date || ''}`.toLowerCase();
		
		// FILTRO 1: Ricerca testuale
		if (filters.search && !searchText.includes(filters.search.toLowerCase())) {
			return false;
		}
		
		// FILTRO 2: Tipo documento (match esatto, case-insensitive)
		if (filters.type && (doc.type || '').toLowerCase() !== filters.type.toLowerCase()) {
			return false;
		}
		
		// FILTRO 3: Stato documento
		if (filters.status && (doc.status || '') !== filters.status) {
			return false;
		}
		
		return true;
	});
}

/**
 * Gestisce il cambio dei filtri.
 * Callback chiamata da Filters.
 */
function onFilter(newFilters: FilterValues) {
	filters = newFilters;
	applyFilters();
}

// ============================================================================
// AUTO-EXPIRATION
// ============================================================================

/**
 * Controlla le date dei documenti e marca come "scaduto" quelli passati.
 * Chiamata all'avvio e ad ogni cambio (tramite reactive statement).
 */
function checkExpirations() {
	const today = new Date().toISOString().slice(0, 10);
	let hasChanges = false;
	
	documents = documents.map(doc => {
		// Se ha una data e è passata, marca come scaduto
		if (doc.date && doc.date < today && doc.status !== 'scaduto') {
			hasChanges = true;
			return { ...doc, status: 'scaduto' as const };
		}
		return doc;
	});
	
	// Salva solo se ci sono stati cambiamenti
	if (hasChanges) {
		save();
	}
}

/**
 * Reactive statement: controlla scadenze quando la lista cambia.
 * In Svelte 5 con runes, questo diventerà $effect().
 */
$: if (documents) {
	checkExpirations();
}

</script>

<!-- ========================================================================== -->
<!-- TEMPLATE -->
<!-- ========================================================================== -->
<main class="min-h-screen bg-gray-100 p-6 sm:p-4">

  <!-- Header -->
  <header class="text-center mb-8">
    <h1 class="text-2xl font-bold text-gray-900 mb-2 sm:text-xl">
      📁 Archivio Documenti
    </h1>
    <p class="text-sm text-gray-600">
      Prototipo gestione documentale con metadati e filtri
    </p>
  </header>

  <!-- Layout a 2 colonne -->
  <div class="grid gap-6 max-w-[1400px] mx-auto grid-cols-1 lg:grid-cols-[1fr_1.5fr]">

    <!-- COLONNA SINISTRA: Upload -->
    <section class="flex flex-col gap-6">
      <div class="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h2 class="text-lg font-semibold text-gray-800 mb-4 pb-2 border-b border-gray-100">
          Carica Documento
        </h2>
        <UploadForm 
          onAdd={addDocument}
          maxFileSize={10}
        />
      </div>
    </section>

    <!-- COLONNA DESTRA: Lista e Filtri -->
    <section class="flex flex-col gap-6">

      <!-- Sezione Filtri -->
      <div class="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
        <Filters 
          onFilter={onFilter}
          debounceMs={300}
        />
      </div>

      <!-- Sezione Lista Documenti -->
      <div class="flex-1 bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <DocumentList 
          documents={filtered}
          onDelete={deleteDocument}
          isLoading={isLoading}
          error={loadingError}
        />
      </div>

    </section>

  </div>

  <!-- Footer info (opzionale) -->
  <footer class="mt-12 pt-6 border-t border-dashed border-gray-300 text-center">
    <p class="text-xs text-gray-400 leading-relaxed">
      ⚠️ Prototipo: i dati sono salvati localmente nel browser.
      {#if documents.length > 0}
        <br>Totale documenti: <strong>{documents.length}</strong>
      {/if}
    </p>
  </footer>

</main>
