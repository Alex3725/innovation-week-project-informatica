# 📋 Guida Migrazione Componenti Svelte 5

## ✅ Modifiche Apportate

### 1. **Pattern Svelte 5: Callback Props**
Sostituito `createEventDispatcher` con callback props come da best practice Svelte 5.

**Prima (Svelte 4):**
```svelte
<script>
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();
  
  function onSubmit() {
    dispatch('add', data);
  }
</script>
```

**Dopo (Svelte 5):**
```svelte
<script lang="ts">
  export let onAdd: (data: Doc) => void;
  
  function onSubmit() {
    onAdd(data);
  }
</script>
```

---

### 2. **Commenti Estensivi**
Ogni componente ora include:
- ✅ Descrizione funzionalità e props
- ✅ Type definitions chiare
- ✅ Commenti su ogni funzione
- ✅ Note per produzione (cosa cambiare)
- ✅ Sezioni organizzate

---

### 3. **Gestione Errori Robusta**
Ogni componente gestisce:
- ✅ Validazione input
- ✅ Try-catch su operazioni async
- ✅ Messaggi errore user-friendly
- ✅ Stati loading/error/empty

**Esempio in UploadForm:**
```typescript
try {
  isLoading = true;
  const dataUrl = await toDataURL(file);
  onAdd(doc);
  resetForm();
} catch (err) {
  error = err instanceof Error 
    ? `Errore: ${err.message}` 
    : 'Errore sconosciuto';
} finally {
  isLoading = false;
}
```

---

### 4. **Accessibilità (a11y)**
- ✅ Label corretti per screen reader
- ✅ ARIA attributes appropriati
- ✅ Focus visibile per navigazione tastiera
- ✅ Supporto prefers-reduced-motion

---

### 5. **Scalabilità**
Ogni componente è pronto per:
- 🔄 Sostituzione localStorage → API backend
- 🔄 Gestione file grandi con FormData
- 🔄 State management (Svelte stores)
- 🔄 Autenticazione/autorizzazione

---

## 🚀 Come Migrare

### Passo 1: Sostituisci i file componenti
Copia i nuovi file nella cartella `src/lib/components/`:
- ✅ `UploadForm.svelte`
- ✅ `DocumentCard.svelte`
- ✅ `DocumentList.svelte`
- ✅ `Filters.svelte`

### Passo 2: Aggiorna +page.svelte
Sostituisci `src/routes/+page.svelte` con la versione aggiornata.

### Passo 3: Verifica che funzioni
```bash
npm run dev
```

Testa:
1. ✅ Upload documento
2. ✅ Visualizza/Scarica documento
3. ✅ Elimina documento
4. ✅ Filtri e ricerca
5. ✅ Persistenza localStorage

---

## 🏗️ Prossimi Step per Produzione

### 1. **Backend API** (Priorità Alta)
Sostituire localStorage con endpoint backend:

```typescript
// UploadForm.svelte - esempio produzione
async function onSubmit(e: Event) {
  e.preventDefault();
  if (!file) return;

  try {
    isLoading = true;
    
    // Usa FormData invece di base64
    const formData = new FormData();
    formData.append('file', file);
    formData.append('type', type);
    formData.append('date', date);
    formData.append('client', client);
    formData.append('status', status);

    // POST al backend
    const response = await fetch('/api/documents', {
      method: 'POST',
      body: formData
    });

    if (!response.ok) {
      throw new Error('Upload fallito');
    }

    const doc = await response.json();
    onAdd(doc); // doc ora contiene URL invece di base64
    resetForm();

  } catch (err) {
    error = `Errore upload: ${err.message}`;
  } finally {
    isLoading = false;
  }
}
```

### 2. **Storage File** (Priorità Alta)
Implementare storage sicuro:
- AWS S3 / MinIO / Supabase Storage
- Pre-signed URLs per download
- Gestione permessi per file

### 3. **Autenticazione** (Priorità Media)
- Login/logout utenti
- Autorizzazione per documenti
- Role-based access control

### 4. **State Management** (Opzionale)
Per app più grandi, considera:
```typescript
// stores/documents.ts
import { writable } from 'svelte/store';

export const documents = writable<Doc[]>([]);
export const filters = writable<FilterValues>({...});

// Azioni
export const actions = {
  async loadDocuments() { ... },
  async addDocument(doc) { ... },
  async deleteDocument(id) { ... }
};
```

### 5. **Ottimizzazioni**
- Paginazione lista documenti
- Virtual scrolling per liste lunghe
- Lazy loading immagini/preview
- Caching intelligente

---

## 📊 Differenze Principali

| Aspetto | Prima | Dopo |
|---------|-------|------|
| Eventi | `createEventDispatcher` | Callback props |
| Errori | Minimi | Try-catch ovunque |
| Commenti | Pochi | Estensivi |
| Validazione | Base | Completa |
| Loading | No | Sì |
| Accessibilità | Base | Completa |
| TypeScript | Parziale | Completo |
| Scalabilità | Limitata | Pronta per produzione |

---

## ⚠️ Note Importanti

### localStorage è temporaneo
Il prototipo usa `localStorage` solo per demo. **Non usare in produzione** perché:
- ❌ Limite ~5-10MB
- ❌ Nessuna sicurezza
- ❌ Nessun backup
- ❌ Solo client-side
- ❌ File base64 inefficienti

### File grandi = Backend obbligatorio
Per file > 5MB:
1. Usa `FormData` invece di base64
2. Implementa endpoint backend per upload
3. Salva file su storage dedicato (S3, ecc.)
4. Salva solo metadati + URL nel database

Vedi documento index 1 per implementazione dettagliata.

---

## 🆘 Troubleshooting

### Errore: "onAdd is not a function"
**Causa:** Stai usando i nuovi componenti con il vecchio pattern eventi.

**Soluzione:** Aggiorna anche `+page.svelte` con la versione fornita.

### Errore TypeScript sui tipi
**Causa:** Mancano definizioni tipo o conflitto versioni.

**Soluzione:**
```bash
npm run check
```
E segui gli errori TypeScript.

### Documenti non si salvano
**Causa:** localStorage pieno o disabilitato.

**Soluzione:** 
- Svuota localStorage manualmente
- Implementa backend (prossimo step)

---

## 📚 Risorse

- [Svelte 5 Docs](https://svelte.dev/docs)
- [SvelteKit API Routes](https://kit.svelte.dev/docs/routing#server)
- [Documento Upload File](vedi index 1 - guida completa)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

## ✨ Conclusione

I componenti sono ora:
- ✅ Svelte 5 compliant
- ✅ Type-safe (TypeScript)
- ✅ Accessibili (a11y)
- ✅ Con gestione errori
- ✅ Ben commentati
- ✅ Pronti per scalare

**Prossimo passo consigliato:** Implementare backend API per upload sicuro e gestione file.

---

**Domande?** Chiedi pure! 👋