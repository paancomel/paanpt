import type { GitHubFileResponse, GitHubPutPayload, GitHubPutResponse } from './types';

const GITHUB_API_BASE = 'https://api.github.com';

function getAuthHeaders() {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    throw new Error('GITHUB_TOKEN is not set');
  }

  return {
    Authorization: `token ${token}`,
    'Content-Type': 'application/json'
  };
}

function getRepoParams() {
  const owner = process.env.GITHUB_OWNER;
  const repo = process.env.GITHUB_REPO;

  if (!owner || !repo) {
    throw new Error('GITHUB_OWNER or GITHUB_REPO is not set');
  }

  return { owner, repo };
}

export async function getFile<T = unknown>(path: string): Promise<GitHubFileResponse<T>> {
  const { owner, repo } = getRepoParams();
  const response = await fetch(`${GITHUB_API_BASE}/repos/${owner}/${repo}/contents/${path}`, {
    headers: getAuthHeaders(),
    cache: 'no-store'
  });

  if (!response.ok) {
    throw new Error(`Failed to load ${path}: ${response.status} ${response.statusText}`);
  }

  const json = await response.json();
  const content = JSON.parse(Buffer.from(json.content, 'base64').toString('utf-8')) as T;
  return { content, sha: json.sha };
}

export async function putFile(path: string, payload: GitHubPutPayload): Promise<GitHubPutResponse> {
  const { owner, repo } = getRepoParams();
  const response = await fetch(`${GITHUB_API_BASE}/repos/${owner}/${repo}/contents/${path}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Failed to save ${path}: ${response.status} ${response.statusText} - ${message}`);
  }

  return (await response.json()) as GitHubPutResponse;
}

export function buildPutPayload<T>(data: T, message: string, sha?: string, branch?: string): GitHubPutPayload {
  return {
    message,
    content: Buffer.from(JSON.stringify(data, null, 2)).toString('base64'),
    ...(sha ? { sha } : {}),
    ...(branch ? { branch } : {})
  };
}
