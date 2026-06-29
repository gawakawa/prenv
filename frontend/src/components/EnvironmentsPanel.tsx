import { useQuery } from '@tanstack/react-query';
import { fetchEnvironments, EnvironmentsUnavailableError } from '../api.ts';
import type { Environment } from '../api.ts';

const statusBadgeClass = (status: string): string => {
	const classes: Record<string, string> = {
		succeeded: 'badge badge-succeeded',
		failed: 'badge badge-failed',
		reconciling: 'badge badge-reconciling',
		pending: 'badge badge-pending',
	};
	return classes[status] ?? 'badge badge-unknown';
};

const formatDate = (iso: string): string => new Date(iso).toLocaleString();

const EnvironmentRow = ({ env }: { env: Environment }) => (
	<tr>
		<td>
			{env.url ? (
				<a className="env-link" href={env.url} target="_blank" rel="noreferrer">
					#{env.pr_number}
				</a>
			) : (
				`#${env.pr_number}`
			)}
		</td>
		<td>{env.name}</td>
		<td>
			<span className={statusBadgeClass(env.status)}>{env.status}</span>
		</td>
		<td>
			{env.commit_sha ? (
				<span className="sha">{env.commit_sha.slice(0, 7)}</span>
			) : (
				<span className="sha muted">—</span>
			)}
		</td>
		<td>{formatDate(env.updated_at)}</td>
	</tr>
);

const EnvironmentsPanel = () => {
	const {
		data: envs,
		isPending,
		isError,
		error,
	} = useQuery({
		queryKey: ['environments'],
		queryFn: fetchEnvironments,
		retry: (_failureCount: number, err: Error) => !(err instanceof EnvironmentsUnavailableError),
	});

	return (
		<section className="panel">
			<h2 className="panel-title">
				Preview Environments{envs !== undefined ? ` (${envs.length})` : ''}
			</h2>
			{isPending ? (
				<p className="notice">Loading…</p>
			) : isError ? (
				error instanceof EnvironmentsUnavailableError ? (
					<p className="notice">プレビュー環境情報は利用できません（Cloud Run の認証が必要です）</p>
				) : (
					<p className="notice error">{error.message}</p>
				)
			) : envs.length === 0 ? (
				<p className="empty-state">オープン中のプレビュー環境はありません</p>
			) : (
				<table className="env-table">
					<thead>
						<tr>
							<th>PR</th>
							<th>Name</th>
							<th>Status</th>
							<th>Commit</th>
							<th>Updated</th>
						</tr>
					</thead>
					<tbody>
						{envs.map((env) => (
							<EnvironmentRow key={env.pr_number} env={env} />
						))}
					</tbody>
				</table>
			)}
		</section>
	);
};

export default EnvironmentsPanel;
