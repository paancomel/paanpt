import type { NextApiRequest, NextApiResponse } from 'next';
import { buildPutPayload, getFile, putFile } from '@/lib/github';
import type { MenuDraft } from '@/lib/types';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const menu = req.body as MenuDraft;
  const path = req.query.path ? String(req.query.path) : `menus/${menu.id}.json`;

  try {
    let sha: string | undefined;
    try {
      const existing = await getFile(path);
      sha = existing.sha;
    } catch (error) {
      sha = undefined;
    }

    const payload = buildPutPayload(menu, `feat(menus): update ${menu.id}`, sha);
    const response = await putFile(path, payload);
    return res.status(200).json(response);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return res.status(500).json({ error: message });
  }
}
