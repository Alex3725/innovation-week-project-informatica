<script lang="ts">
/**
 * Filters.svelte
 * 
 * Componente per filtrare e cercare documenti.
 * Supporta ricerca testuale, filtro per tipo e filtro per stato.
 * Pattern Svelte 5: usa callback props invece di eventi custom.
 * 
 * Props:
 * - onFilter: callback chiamata quando i filtri cambiano
 * - initialSearch: valore iniziale ricerca (opzionale)
 * - initialType: valore iniziale tipo (opzionale)
 * - initialStatus: valore iniziale stato (opzionale)
 * - debounceMs: millisecondi di debounce per la ricerca (default: 300)
 */

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/** Struttura dei filtri applicati */
type FilterValues = {
  search: string;
  type: string;
  status: '' | 'attivo' | 'in revisione' | 'scaduto';
};

// ============================================================================
// PROPS
// ============================================================================

/** Callback chiamata quando cambiano i filtri */
export let onFilter: (filters: FilterValues) => void;

/** Valore iniziale per la ricerca */
export let initialSearch: string = '';

/** Valore iniziale per il tipo */
export let initialType: string = '';

/** Valore iniziale per lo stato */
export let initialStatus: '' | 'attivo' | 'in revisione' | 'scaduto' = '';

/** Millisecondi di debounce per evitare troppe chiamate (default: 300ms) */
export let debounceMs: number = 300;

// ============================================================================
// STATE
// ============================================================================

/** Valore corrente ricerca */
let search: string = initialSearch;

/** Valore corrente tipo */
let type: string = initialType;

/** Valore corrente stato */
let status: '' | 'attivo' | 'in revisione' | 'scaduto' = initialStatus;

/** Timer per il debounce della ricerca */
let debounceTimer: ReturnType<typeof setTimeout> | null = null;

/** Flag: indica se ci sono filtri attivi */
$: hasActiveFilters = search.trim() !== '' || type.trim() !== '' || status !== '';

/** Conteggio filtri attivi */
$: activeFiltersCount = [
  search.trim() !== '',
  type.trim() !== '',
  status !== ''
].filter(Boolean).length;

// ============================================================================
// HANDLERS
// ============================================================================

/**
 * Applica i filtri correnti chiamando il callback onFilter.
 * Questa funzione viene chiamata immediatamente per select/button,
 * ma con debounce per l'input di ricerca.
 */
function applyFilters() {
  // Pulisci gli spazi bianchi
  const cleanSearch = search.trim();
  const cleanType = type.trim();

  // Crea oggetto filtri
  const filters: FilterValues = {
    search: cleanSearch,
    type: cleanType,
    status: status
  };

  // Chiama callback parent
  onFilter(filters);
}

/**
 * Gestisce il cambio dell'input di ricerca con debounce.
 * Evita di chiamare onFilter ad ogni keystroke.
 */
function handleSearchInput() {
  // Cancella timer precedente se esiste
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }

  // Imposta nuovo timer
  debounceTimer = setTimeout(() => {
    applyFilters();
  }, debounceMs);
}

/**
 * Gestisce il cambio del filtro tipo (immediato, senza debounce).
 */
function handleTypeChange() {
  applyFilters();
}

/**
 * Gestisce il cambio del filtro stato (immediato, senza debounce).
 */
function handleStatusChange() {
  applyFilters();
}

/**
 * Resetta tutti i filtri ai valori di default.
 */
function resetFilters() {
  // Cancella timer debounce se attivo
  if (debounceTimer) {
    clearTimeout(debounceTimer);
    debounceTimer = null;
  }

  // Reset valori
  search = '';
  type = '';
  status = '';

  // Applica reset
  applyFilters();
}

// ============================================================================
// LIFECYCLE
// ============================================================================

/**
 * Cleanup: cancella timer quando il componente viene distrutto.
 */
import { onDestroy } from 'svelte';

onDestroy(() => {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }
});
</script>

<!-- ========================================================================== -->
<!-- TEMPLATE -->
<!-- ========================================================================== -->

<div class="filters-container">
  
  <!-- Barra filtri -->
  <div class="filters-bar">
    
    <!-- Campo Ricerca -->
    <div class="filter-field search-field">
      <label for="search-input" class="sr-only">Cerca documenti</label>
      <input 
        id="search-input"
        type="text"
        placeholder="🔍 Cerca per nome, tipo, cliente..."
        bind:value={search}
        on:input={handleSearchInput}
        class="search-input"
      />
    </div>

    <!-- Campo Tipo -->
    <div class="filter-field type-field">
      <label for="type-input" class="sr-only">Filtra per tipo</label>
      <input 
        id="type-input"
        type="text"
        placeholder="Tipo documento"
        bind:value={type}
        on:input={handleTypeChange}
        class="type-input"
      />
    </div>

    <!-- Campo Stato -->
    <div class="filter-field status-field">
      <label for="status-select" class="sr-only">Filtra per stato</label>
      <select 
        id="status-select"
        bind:value={status}
        on:change={handleStatusChange}
        class="status-select"
      >
        <option value="">Tutti gli stati</option>
        <option value="attivo">Attivo</option>
        <option value="in revisione">In revisione</option>
        <option value="scaduto">Scaduto</option>
      </select>
    </div>

    <!-- Bottone Reset -->
    <button 
      class="reset-btn"
      on:click={resetFilters}
      disabled={!hasActiveFilters}
      title="Rimuovi tutti i filtri"
    >
      {#if hasActiveFilters}
        ✕ Reset ({activeFiltersCount})
      {:else}
        Reset
      {/if}
    </button>

  </div>

  <!-- Indicatore filtri attivi (mobile-friendly) -->
  {#if hasActiveFilters}
    <div class="active-filters-indicator">
      <span class="indicator-label">Filtri attivi:</span>
      
      {#if search.trim()}
        <span class="filter-tag">
          Ricerca: "{search.trim()}"
          <button 
            class="tag-remove"
            on:click={() => { search = ''; applyFilters(); }}
            aria-label="Rimuovi filtro ricerca"
          >
            ✕
          </button>
        </span>
      {/if}

      {#if type.trim()}
        <span class="filter-tag">
          Tipo: {type.trim()}
          <button 
            class="tag-remove"
            on:click={() => { type = ''; applyFilters(); }}
            aria-label="Rimuovi filtro tipo"
          >
            ✕
          </button>
        </span>
      {/if}

      {#if status}
        <span class="filter-tag">
          Stato: {status}
          <button 
            class="tag-remove"
            on:click={() => { status = ''; applyFilters(); }}
            aria-label="Rimuovi filtro stato"
          >
            ✕
          </button>
        </span>
      {/if}
    </div>
  {/if}

</div>

<!-- ========================================================================== -->
<!-- STYLES -->
<!-- ========================================================================== -->

<style>
  .filters-container {
    width: 100%;
    margin-bottom: 1rem;
  }

  .filters-bar {
    display: flex;
    gap: 0.6rem;
    align-items: stretch;
  }

  .filter-field {
    flex: 1;
    min-width: 0; /* Permette shrink */
  }

  /* Screen reader only (accessibilità) */
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
  }

  /* Stili comuni input */
  .search-input,
  .type-input,
  .status-select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.9rem;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  .search-input:focus,
  .type-input:focus,
  .status-select:focus {
    outline: none;
    border-color: #4a90e2;
    box-shadow: 0 0 0 3px rgba(74, 144, 226, 0.1);
  }

  /* Campo ricerca più ampio */
  .search-field {
    flex: 2;
  }

  /* Select stato */
  .status-select {
    cursor: pointer;
  }

  /* Bottone reset */
  .reset-btn {
    padding: 0.5rem 1rem;
    background: white;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.2s;
    white-space: nowrap;
  }

  .reset-btn:hover:not(:disabled) {
    background: #f5f5f5;
    border-color: #bbb;
  }

  .reset-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  /* Indicatore filtri attivi */
  .active-filters-indicator {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: center;
    margin-top: 0.8rem;
    padding: 0.6rem;
    background: #f8f9fa;
    border-radius: 4px;
  }

  .indicator-label {
    font-size: 0.85rem;
    font-weight: 500;
    color: #666;
  }

  .filter-tag {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    padding: 0.25rem 0.6rem;
    background: white;
    border: 1px solid #ddd;
    border-radius: 12px;
    font-size: 0.85rem;
    color: #333;
  }

  .tag-remove {
    background: none;
    border: none;
    padding: 0;
    cursor: pointer;
    color: #999;
    font-size: 0.9rem;
    line-height: 1;
    transition: color 0.2s;
  }

  .tag-remove:hover {
    color: #c33;
  }

  /* ===== RESPONSIVE ===== */

  @media (max-width: 768px) {
    .filters-bar {
      flex-wrap: wrap;
    }

    .search-field {
      flex: 1 1 100%; /* Full width su mobile */
    }

    .type-field,
    .status-field {
      flex: 1 1 calc(50% - 0.3rem);
    }

    .reset-btn {
      flex: 1 1 100%;
    }
  }

  @media (max-width: 480px) {
    .filters-bar {
      flex-direction: column;
    }

    .search-field,
    .type-field,
    .status-field,
    .reset-btn {
      width: 100%;
    }
  }

  /* ===== ACCESSIBILITÀ ===== */

  /* Focus visibile per navigazione tastiera */
  .reset-btn:focus-visible {
    outline: 2px solid #4a90e2;
    outline-offset: 2px;
  }

  .tag-remove:focus-visible {
    outline: 2px solid #4a90e2;
    outline-offset: 1px;
    border-radius: 2px;
  }
</style>