


<script lang="ts">
	import { onMount } from 'svelte';
	import { UploadForm, DocumentList, Filters } from '$lib';

	type Doc = {
		id: string;
		name: string;
		fileData: string;
		mime?: string;
		type?: string;
		date?: string;
		client?: string;
		status?: string;
		uploadedAt?: string;
	};

	let documents: Doc[] = [];
	let filtered: Doc[] = [];
	let filters = { search: '', type: '', status: '' };

	const STORAGE_KEY = 'docs-proto';

	onMount(()=>{
		const raw = localStorage.getItem(STORAGE_KEY);
		documents = raw ? JSON.parse(raw) : [];
		applyFilters();
	});

	function save() {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(documents));
		applyFilters();
	}

	function addDocument(e: CustomEvent) {
		documents = [e.detail, ...documents];
		save();
	}

	function deleteDocument(e: CustomEvent | string) {
		const id = typeof e === 'string' ? e : e.detail;
		documents = documents.filter(d=>d.id !== id);
		save();
	}

	function applyFilters() {
		filtered = documents.filter(d=>{
			const text = `${d.name} ${d.type || ''} ${d.client || ''} ${d.date || ''}`.toLowerCase();
			if (filters.search && !text.includes(filters.search.toLowerCase())) return false;
			if (filters.type && ((d.type||'').toLowerCase() !== filters.type.toLowerCase())) return false;
			if (filters.status && (d.status || '') !== filters.status) return false;
			return true;
		});
	}

	function onFilter(e: CustomEvent) {
		filters = e.detail;
		applyFilters();
	}

	$: checkExpirations();

	function checkExpirations(){
		const today = new Date().toISOString().slice(0,10);
		let changed = false;
		documents = documents.map(d=>{
			if (d.date && d.date < today && d.status !== 'scaduto') { changed = true; return {...d, status: 'scaduto'} }
			return d;
		});
		if (changed) save();
	}
</script>

<main>
	<h1>Archivio Documenti — Prototipo</h1>

	<section class="left">
		<UploadForm on:add={addDocument} />
	</section>

	<section class="right">
		<Filters on:filter={onFilter} />
		<DocumentList documents={filtered} on:delete={(e)=>deleteDocument(e.detail)} />
	</section>

</main>

<style>
main{display:grid;grid-template-columns:1fr 1fr;gap:1rem;padding:1rem}
.left{border-right:1px dashed #ddd;padding-right:1rem}
.right{padding-left:1rem}
h1{font-size:1.2rem;margin-bottom:0.6rem}
</style>
