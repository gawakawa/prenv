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
				<table className="env-table">
					<thead>
						<tr>
							<th>id</th>
							<th>body</th>
						</tr>
					</thead>
					<tbody>
						{messages.map((m) => (
							<tr key={m.id}>
								<td>{m.id}</td>
								<td>{m.body}</td>
							</tr>
						))}
					</tbody>
				</table>
			)}
		</section>
	);
};

export default MessagesPanel;
