export class EnvironmentsUnavailableError extends Error {}

export type Prenv = {
	pr_number: number;
	name: string;
	url: string;
	status: string;
	commit_sha: string;
	updated_at: string;
};

export const fetchPrenvs = async (): Promise<Prenv[]> => {
	const r = await fetch('/api/prenvs');
	if (r.status === 503) {
		throw new EnvironmentsUnavailableError('monitoring unavailable');
	}
	if (!r.ok) {
		throw new Error(`Failed to fetch prenvs: ${r.status}`);
	}
	return r.json();
};
