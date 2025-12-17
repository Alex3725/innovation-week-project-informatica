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
import { UploadForm, DocumentList, Filters } from '$lib';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/** Struttura completa del documento */
type Doc = {
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
 * Aggiunge un nuovo documento alla lista.
 * Callback chiamata da UploadForm.
 */
function addDocument(doc: Doc) {
	// Aggiungi in cima alla lista (più recenti prima)
	documents = [doc, ...documents];
	save();
	
	// Log per debug (rimuovere in produzione)
	console.log('Documento aggiunto:', doc.name);
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

<main class="app-main">
	
	<!-- Header -->
	<header class="app-header">
		<h1 class="app-title">
			📁 Archivio Documenti
		</h1>
		<p class="app-subtitle">
			Prototipo gestione documentale con metadati e filtri
		</p>
	</header>

	<!-- Layout a 2 colonne -->
	<div class="app-layout">
		
		<!-- COLONNA SINISTRA: Upload -->
		<section class="left-column">
			<div class="section-card">
				<h2 class="section-title">Carica Documento</h2>
				<UploadForm 
					onAdd={addDocument}
					maxFileSize={10}
				/>
			</div>
		</section>

		<!-- COLONNA DESTRA: Lista e Filtri -->
		<section class="right-column">
			
			<!-- Sezione Filtri -->
			<div class="section-card filters-card">
				<Filters 
					onFilter={onFilter}
					debounceMs={300}
				/>
			</div>

			<!-- Sezione Lista Documenti -->
			<div class="section-card list-card">
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
	<footer class="app-footer">
		<p class="footer-text">
			⚠️ Prototipo: i dati sono salvati localmente nel browser.
			{#if documents.length > 0}
				<br>Totale documenti: <strong>{documents.length}</strong>
			{/if}
		</p>
	</footer>

</main>

<!-- ========================================================================== -->
<!-- STYLES -->
<!-- ========================================================================== -->

<style>
	/* ===== LAYOUT PRINCIPALE ===== */

	.app-main {
		min-height: 100vh;
		background: #f8f9fa;
		padding: 1.5rem;
	}

	.app-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.app-title {
		font-size: 1.8rem;
		font-weight: 700;
		color: #222;
		margin-bottom: 0.5rem;
	}

	.app-subtitle {
		font-size: 0.95rem;
		color: #666;
	}

	/* ===== LAYOUT A 2 COLONNE ===== */

	.app-layout {
		display: grid;
		grid-template-columns: 1fr 1.5fr;
		gap: 1.5rem;
		max-width: 1400px;
		margin: 0 auto;
	}

	/* Colonne */
	.left-column,
	.right-column {
		display: flex;
		flex-direction: column;
		gap: 1.5rem;
	}

	/* Card sezioni */
	.section-card {
		background: white;
		border: 1px solid #e0e0e0;
		border-radius: 8px;
		padding: 1.5rem;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
	}

	.section-title {
		font-size: 1.1rem;
		font-weight: 600;
		color: #333;
		margin-bottom: 1rem;
		padding-bottom: 0.5rem;
		border-bottom: 2px solid #f0f0f0;
	}

	.filters-card {
		padding: 1rem;
	}

	.list-card {
		flex: 1;
	}

	/* ===== FOOTER ===== */

	.app-footer {
		margin-top: 3rem;
		padding-top: 1.5rem;
		border-top: 1px dashed #ddd;
		text-align: center;
	}

	.footer-text {
		font-size: 0.85rem;
		color: #999;
		line-height: 1.6;
	}

	/* ===== RESPONSIVE ===== */

	/* Tablet */
	@media (max-width: 1024px) {
		.app-layout {
			grid-template-columns: 1fr;
		}
	}

	/* Mobile */
	@media (max-width: 640px) {
		.app-main {
			padding: 1rem;
		}

		.app-title {
			font-size: 1.4rem;
		}

		.section-card {
			padding: 1rem;
		}

		.app-footer {
			margin-top: 2rem;
		}
	}

	/* ===== PRINT STYLES ===== */

	@media print {
		.app-main {
			background: white;
		}

		.left-column,
		.app-footer {
			display: none;
		}

		.section-card {
			box-shadow: none;
			border: 1px solid #ddd;
		}
	}
</style>