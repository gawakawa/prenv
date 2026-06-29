export class EnvironmentsUnavailableError extends Error {}

export type Environment = {
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

export const fetchEnvironments = async (): Promise<Environment[]> => {
	const r = await fetch('/api/environments');
	if (r.status === 503) {
		throw new EnvironmentsUnavailableError('monitoring unavailable');
	}
	if (!r.ok) {
		throw new Error(`Failed to fetch environments: ${r.status}`);
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
