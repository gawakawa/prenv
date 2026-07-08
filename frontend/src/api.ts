export type Prenv = {
	pr_number: number;
	name: string;
	url: string;
	status: string;
	commit_sha: string;
	updated_at: string;
};

export type Message = {
	id: number;
	body: string;
};

export const fetchPrenvs = async (): Promise<Prenv[]> => {
	const r = await fetch('/api/prenvs');
	if (!r.ok) {
		throw new Error(`Failed to fetch prenvs: ${r.status}`);
	}
	return r.json();
};

export const fetchMessages = async (): Promise<Message[]> => {
	const r = await fetch('/api/messages');
	if (!r.ok) {
		throw new Error(`Failed to fetch messages: ${r.status}`);
	}
	return r.json();
};
