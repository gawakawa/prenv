import { useQuery } from '@tanstack/react-query';
import { fetchPrenvs, type Prenv } from '../api.ts';

const GITHUB_REPO = 'gawakawa/prenv';
const formatJst = (iso: string): string =>
	Temporal.Instant.from(iso).toZonedDateTimeISO('Asia/Tokyo').toLocaleString('ja-JP');
const KNOWN_STATUSES = new Set(['succeeded', 'failed', 'reconciling', 'pending', 'torn_down']);
const statusBadgeClass = (status: string): string =>
	KNOWN_STATUSES.has(status) ? `badge badge-${status}` : 'badge badge-unknown';

const PrenvRow = ({ prenv }: { prenv: Prenv }) => {
	const displayName = prenv.name || `pr-${prenv.pr_number}`;

	return (
		<tr>
			<td>
				<a
					className="env-link"
					href={`https://github.com/${GITHUB_REPO}/pull/${prenv.pr_number}`}
					target="_blank"
					rel="noreferrer"
				>
					#{prenv.pr_number}
				</a>
			</td>
			<td>
				{prenv.url ? (
					<a className="env-link" href={prenv.url} target="_blank" rel="noreferrer">
						{displayName}
					</a>
				) : (
					displayName
				)}
			</td>
			<td>
				<span className={statusBadgeClass(prenv.status)}>{prenv.status}</span>
			</td>
			<td>
				{prenv.commit_sha ? (
					prenv.commit_sha.length === 40 ? (
						<a
							className="sha env-link"
							href={`https://github.com/${GITHUB_REPO}/commit/${prenv.commit_sha}`}
							target="_blank"
							rel="noreferrer"
						>
							{prenv.commit_sha.slice(0, 7)}
						</a>
					) : (
						<span className="sha">{prenv.commit_sha.slice(0, 7)}</span>
					)
				) : (
					<span className="sha muted">—</span>
				)}
			</td>
			<td>{formatJst(prenv.updated_at)}</td>
		</tr>
	);
};

const PrenvsPanel = () => {
	const {
		data: prenvs,
		isPending,
		isError,
		error,
	} = useQuery({
		queryKey: ['prenvs'],
		queryFn: fetchPrenvs,
		retry: (failureCount) => failureCount < 3,
	});

	return (
		<section className="panel">
			<h2 className="panel-title">Preview Environments{prenvs && ` (${prenvs.length})`}</h2>
			{isPending ? (
				<p className="notice">Loading…</p>
			) : isError ? (
				<p className="notice error">{error.message}</p>
			) : prenvs.every((p) => p.status === 'torn_down') ? (
				<p className="empty-state">稼働中のプレビュー環境はありません</p>
			) : (
				<table className="env-table">
					<thead>
						<tr>
							<th>PR</th>
							<th>Name</th>
							<th>Status</th>
							<th>Commit</th>
							<th>Updated (JST)</th>
						</tr>
					</thead>
					<tbody>
						{prenvs.map((prenv) => (
							<PrenvRow key={prenv.pr_number} prenv={prenv} />
						))}
					</tbody>
				</table>
			)}
		</section>
	);
};

export default PrenvsPanel;
