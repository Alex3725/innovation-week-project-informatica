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
<div class="mb-4 w-full">

  <!-- ================= FILTRI ================= -->
  <div
    class="
      flex items-stretch gap-2
      flex-wrap
    "
  >
    <!-- ================= SEARCH ================= -->
    <div class="flex-[2] min-w-0 max-md:flex-[1] max-md:w-full">
      <label for="search-input" class="sr-only">
        Cerca documenti
      </label>

      <input
        id="search-input"
        type="text"
        placeholder="🔍 Cerca per nome, tipo, cliente..."
        bind:value={search}
        on:input={handleSearchInput}
        class="
          w-full rounded border border-gray-300
          px-2 py-2 text-sm
          transition
          focus:outline-none focus:ring-2 focus:ring-blue-200
        "
      />
    </div>

    <!-- ================= TIPO ================= -->
    <div class="flex-1 min-w-0 max-md:w-[calc(50%-0.25rem)] max-sm:w-full">
      <label for="type-input" class="sr-only">
        Filtra per tipo
      </label>

      <input
        id="type-input"
        type="text"
        placeholder="Tipo documento"
        bind:value={type}
        on:input={handleTypeChange}
        class="
          w-full rounded border border-gray-300
          px-2 py-2 text-sm
          transition
          focus:outline-none focus:ring-2 focus:ring-blue-200
        "
      />
    </div>

    <!-- ================= STATO ================= -->
    <div class="flex-1 min-w-0 max-md:w-[calc(50%-0.25rem)] max-sm:w-full">
      <label for="status-select" class="sr-only">
        Filtra per stato
      </label>

      <select
        id="status-select"
        bind:value={status}
        on:change={handleStatusChange}
        class="
          w-full cursor-pointer rounded border border-gray-300
          px-2 py-2 text-sm
          transition
          focus:outline-none focus:ring-2 focus:ring-blue-200
        "
      >
        <option value="">Tutti gli stati</option>
        <option value="attivo">Attivo</option>
        <option value="in revisione">In revisione</option>
        <option value="scaduto">Scaduto</option>
      </select>
    </div>

    <!-- ================= RESET ================= -->
    <button
      on:click={resetFilters}
      disabled={!hasActiveFilters}
      title="Rimuovi tutti i filtri"
      class="
        whitespace-nowrap rounded border border-gray-300
        px-4 py-2 text-sm
        transition
        hover:border-gray-400 hover:bg-gray-100
        disabled:cursor-not-allowed disabled:opacity-50
        max-md:w-full
      "
    >
      {#if hasActiveFilters}
        ✕ Reset ({activeFiltersCount})
      {:else}
        Reset
      {/if}
    </button>
  </div>

  <!-- ================= FILTRI ATTIVI ================= -->
  {#if hasActiveFilters}
    <div
      class="
        mt-3 flex flex-wrap items-center gap-2
        rounded bg-gray-50 px-3 py-2
      "
    >
      <span class="text-sm font-medium text-gray-600">
        Filtri attivi:
      </span>

      {#if search.trim()}
        <span
          class="
            inline-flex items-center gap-1.5
            rounded-full border border-gray-300
            bg-white px-3 py-1
            text-sm text-gray-800
          "
        >
          Ricerca: "{search.trim()}"
          <button
            on:click={() => { search = ''; applyFilters(); }}
            aria-label="Rimuovi filtro ricerca"
            class="
              text-gray-400 transition
              hover:text-red-500
              focus:outline-none focus-visible:ring-2
              focus-visible:ring-blue-400
              rounded
            "
          >
            ✕
          </button>
        </span>
      {/if}

      {#if type.trim()}
        <span
          class="
            inline-flex items-center gap-1.5
            rounded-full border border-gray-300
            bg-white px-3 py-1
            text-sm text-gray-800
          "
        >
          Tipo: {type.trim()}
          <button
            on:click={() => { type = ''; applyFilters(); }}
            aria-label="Rimuovi filtro tipo"
            class="
              text-gray-400 transition
              hover:text-red-500
              focus:outline-none focus-visible:ring-2
              focus-visible:ring-blue-400
              rounded
            "
          >
            ✕
          </button>
        </span>
      {/if}

      {#if status}
        <span
          class="
            inline-flex items-center gap-1.5
            rounded-full border border-gray-300
            bg-white px-3 py-1
            text-sm text-gray-800
          "
        >
          Stato: {status}
          <button
            on:click={() => { status = ''; applyFilters(); }}
            aria-label="Rimuovi filtro stato"
            class="
              text-gray-400 transition
              hover:text-red-500
              focus:outline-none focus-visible:ring-2
              focus-visible:ring-blue-400
              rounded
            "
          >
            ✕
          </button>
        </span>
      {/if}
    </div>
  {/if}

</div>
