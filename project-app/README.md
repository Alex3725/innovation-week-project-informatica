# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project in the current directory
````markdown
# Prototipo Archivio Documenti (SvelteKit)

Questa cartella contiene un prototipo client-side per un sistema di archiviazione documentale (senza API): upload locale, metadati inseriti dall'utente, ricerca e filtri. È pensato come primo passo per il progetto Informatica, seguendo lo style del cliente.

## Struttura rilevante

- `src/lib/components/UploadForm.svelte` — form per caricare file e inserire metadati (tipo, data, cliente, stato).
- `src/lib/components/DocumentCard.svelte` — visualizza singolo documento (vedi, scarica, elimina).
- `src/lib/components/DocumentList.svelte` — elenco documenti.
- `src/lib/components/Filters.svelte` — ricerca e filtri.
- `src/lib/index.ts` — esporta i componenti per semplice import.
- `src/routes/+page.svelte` — pagina principale del prototipo: integra i componenti e gestisce i dati lato client.

## Come provare il prototipo (locale)

1. Apri la cartella `project-app`.
2. Installa le dipendenze:

```bash
npm install
```

3. Avvia il dev server:

```bash
npm run dev -- --open
```

4. In pagina puoi:
- Caricare un file usando il form nella colonna sinistra (inserire tipo, data, cliente, stato).
- Visualizzare o scaricare il documento dalla lista a destra.
- Eliminare documenti con il pulsante "Elimina".
- Usare la barra di ricerca e i filtri per trovare documenti.

I dati sono salvati nel `localStorage` del browser sotto la chiave `docs-proto` (solo per prototipo). Questo significa che i documenti restano disponibili nel browser finché non vengono rimossi o si cancella lo storage.

## Note tecniche e limiti

- Questo prototipo NON invia file a nessun server: i file vengono codificati in base64 e memorizzati nel `localStorage`. Non usare per dati sensibili.
- Non c'è gestione utenti o permessi.
- La classificazione automatica (OCR/AI) non è inclusa in questa fase: i metadati vengono inseriti dall'utente.

## Prossimi passi consigliati

- Aggiungere una semplice API mock / endpoint per salvare i documenti su disco o DB (quando pronto).
- Implementare upload server-side e storage sicuro (es. S3, Blob storage).
- Integrazione OCR e classificazione automatica.
- Aggiungere autenticazione e gestione permessi per team.

## Contatti

Se vuoi che aggiunga ora l'API mock o preferisci che proceda con le istruzioni per il deploy, dimmi quale opzione preferisci.

````
