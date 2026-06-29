import { useQuery } from '@tanstack/react-query';
import { fetchMessages } from '../api.ts';

const MessagesPanel = () => {
	const {
		data: messages,
		isPending,
		isError,
		error,
	} = useQuery({
		queryKey: ['messages'],
		queryFn: fetchMessages,
	});

	return (
		<section className="panel">
			<h2 className="panel-title">Database</h2>
			{isPending ? (
				<p className="notice">Loading…</p>
			) : isError ? (
				<p className="notice error">{error.message}</p>
			) : (
				<ul className="messages-list">
					{messages.map((m) => (
						<li key={m.id}>{m.body}</li>
					))}
				</ul>
			)}
		</section>
	);
};

export default MessagesPanel;
