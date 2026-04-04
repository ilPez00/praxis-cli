#!/usr/bin/env node
/**
 * Praxis CLI v2 - Full TUI client for the Praxis webapp.
 *
 * Notebook model (git-like):
 *   Each topic = a "repo" (~/.praxis/notebook/<topic>/)
 *   Each entry = a "commit" (SHA, parent chain, message, content, mood, tags)
 *   History = linked list via parent pointers (git log)
 *   Tags = milestones (git tag)
 *   Diff = compare entries (git diff)
 *   Sync = push/pull to webapp API
 */
import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import Table from 'cli-table3';
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { createHash } from 'crypto';

const CONFIG_DIR = join(homedir(), '.config', 'praxis');
const CONFIG_FILE = join(CONFIG_DIR, 'config.json');
const DATA_DIR = join(homedir(), '.praxis');

interface Cfg {
  apiUrl: string;
  token?: string;
  userId?: string;
  userName?: string;
  lastSync?: string;
}

interface Entry {
  sha: string;
  parent: string | null;
  message: string;
  content: string;
  mood?: string;
  tags?: string[];
  author: string;
  createdAt: string;
}

interface Topic {
  name: string;
  head: string | null;
  entryCount: number;
  lastEntryAt: string | null;
}

function loadCfg(): Cfg {
  try { return JSON.parse(readFileSync(CONFIG_FILE, 'utf8')); }
  catch { return { apiUrl: 'https://web-production-646a4.up.railway.app/api' }; }
}

function saveCfg(c: Cfg): void {
  mkdirSync(CONFIG_DIR, { recursive: true });
  writeFileSync(CONFIG_FILE, JSON.stringify(c, null, 2));
}

const th = {
  p: chalk.hex('#F59E0B'),
  s: chalk.hex('#8B5CF6'),
  ok: chalk.hex('#10B981'),
  err: chalk.hex('#EF4444'),
  inf: chalk.hex('#3B82F6'),
  dim: chalk.dim,
  b: chalk.bold,
  fire: (d: number): string => d >= 30 ? chalk.hex('#F59E0B').bold(`\uD83D\uDD25 ${d}d`) : d >= 7 ? chalk.hex('#10B981')(`\uD83D\uDD25 ${d}d`) : d >= 1 ? chalk.hex('#3B82F6')(`\uD83D\uDD25 ${d}d`) : chalk.dim('No streak'),
  star: chalk.hex('#F59E0B')('\u2B50'),
  logo: (): string => `${chalk.hex('#F59E0B').bold('PRAXIS')} ${chalk.dim('CLI')}`,
  card: (t: string, body: string, w = 60): string => {
    const br = chalk.hex('#374151')('\u2500'.repeat(w));
    return `${br}\n ${th.p('\u25C6')} ${th.b(t)} \n${br}\n${body.split('\n').map(l => '  ' + l).join('\n')}\n${br}`;
  },
  row: (l: string, v: string): string => '  ' + chalk.dim(l.padEnd(20)) + ' ' + v,
  bar: (c: number, m: number, w = 25): string => {
    const p = Math.min(c / m, 1);
    const f = Math.round(p * w);
    return th.p('\u2588'.repeat(f)) + chalk.dim('\u2591'.repeat(w - f)) + ' ' + Math.round(p * 100) + '%';
  },
};

class Api {
  constructor(private c: Cfg) {}
  private h(): Record<string, string> {
    const o: Record<string, string> = { 'Content-Type': 'application/json' };
    if (this.c.token) o.Authorization = 'Bearer ' + this.c.token;
    return o;
  }
  private async r<T>(m: string, p: string, b?: unknown): Promise<T> {
    const u = this.c.apiUrl + p;
    const res = await fetch(u, { method: m, headers: this.h(), body: b ? JSON.stringify(b) : undefined });
    if (!res.ok) throw new Error('API ' + res.status + ': ' + await res.text());
    const t = await res.text();
    return t ? (JSON.parse(t) as T) : ({} as T);
  }
  get<T>(p: string) { return this.r<T>('GET', p); }
  post<T>(p: string, b?: unknown) { return this.r<T>('POST', p, b); }
  login(e: string, pw: string) { return this.post<{ token: string; user: Record<string, string> }>('/auth/login', { email: e, password: pw }); }
  dashboard() { return this.get<Record<string, unknown>>('/dashboard'); }
  goals() { return this.get<Array<Record<string, unknown>>>('/goals'); }
  createGoal(d: unknown) { return this.post<Record<string, unknown>>('/goals', d); }
  journal(gid?: string) { return this.get<Array<Record<string, unknown>>>(gid ? '/journal?goal_id=' + gid : '/journal'); }
  createEntry(d: unknown) { return this.post<Record<string, unknown>>('/journal', d); }
  checkin(n?: string) { return this.post<Record<string, number>>('/checkins', { note: n }); }
  streak() { return this.get<Record<string, number>>('/checkins/streak'); }
  bets() { return this.get<Array<Record<string, unknown>>>('/bets'); }
  createBet(d: unknown) { return this.post<Record<string, unknown>>('/bets', d); }
  cancelBet(id: string) { return this.post<Record<string, unknown>>('/bets/' + id, { cancel: true }); }
  points() { return this.get<Record<string, number>>('/points/balance'); }
  // Messages
  messages(u1: string, u2: string) { return this.get<Array<Record<string, unknown>>>('/messages/' + u1 + '/' + u2); }
  sendMessage(d: unknown) { return this.post<Record<string, unknown>>('/messages/send', d); }
  // Axiom
  axiomBrief() { return this.get<Record<string, unknown>>('/ai-coaching/brief'); }
  axiomDailyBrief() { return this.get<Record<string, unknown>>('/ai-coaching/daily-brief'); }
  axiomRegenerate() { return this.post<Record<string, unknown>>('/axiom/regenerate'); }
  axiomNarrative() { return this.post<Record<string, unknown>>('/ai-coaching/weekly-narrative'); }
  axiomChat(msg: string) { return this.post<Record<string, unknown>>('/ai-coaching/request', { message: msg }); }
  // Notebook (webapp)
  notebookEntries(opts?: { entry_type?: string; domain?: string; search?: string; goal_id?: string; limit?: number }) {
    const p = new URLSearchParams();
    if (opts?.entry_type) p.set('entry_type', opts.entry_type);
    if (opts?.domain) p.set('domain', opts.domain);
    if (opts?.search) p.set('search', opts.search);
    if (opts?.goal_id) p.set('goal_id', opts.goal_id);
    if (opts?.limit) p.set('limit', String(opts.limit));
    const q = p.toString();
    return this.get<Array<Record<string, unknown>>>('/notebook/entries' + (q ? '?' + q : ''));
  }
  createNotebookEntry(d: unknown) { return this.post<Record<string, unknown>>('/notebook/entries', d); }
  notebookStats() { return this.get<Record<string, unknown>>('/notebook/stats'); }
  // Places (map)
  places() { return this.get<Array<Record<string, unknown>>>('/places'); }
  createPlace(d: unknown) { return this.post<Record<string, unknown>>('/places', d); }
  joinPlace(id: string) { return this.post<Record<string, unknown>>('/places/' + id + '/join'); }
  // Matches
  matches() { return this.get<Array<Record<string, unknown>>>('/matches'); }
}

function nbDir(t: string): string {
  const d = join(DATA_DIR, 'notebook', t.replace(/[^a-z0-9_-]/gi, '_').toLowerCase());
  mkdirSync(join(d, 'entries'), { recursive: true });
  return d;
}

function headF(t: string): string { return join(nbDir(t), 'HEAD'); }

function readH(t: string): string | null {
  try { const h = readFileSync(headF(t), 'utf8').trim(); return h || null; } catch { return null; }
}

function writeH(t: string, s: string): void { writeFileSync(headF(t), s); }

function computeSha(e: Omit<Entry, 'sha'>): string {
  return createHash('sha1').update(JSON.stringify({ p: e.parent, m: e.message, c: e.content, mood: e.mood, a: e.author, t: e.createdAt })).digest('hex').slice(0, 12);
}

function addEntry(topic: string, msg: string, content: string, author: string, opts?: { parent?: string; mood?: string; tags?: string[] }): Entry {
  let parent = opts?.parent ?? readH(topic);
  const d: Omit<Entry, 'sha'> = { parent, message: msg, content, mood: opts?.mood, tags: opts?.tags, author, createdAt: new Date().toISOString() };
  const s = computeSha(d);
  const full: Entry = { ...d, sha: s };
  writeFileSync(join(nbDir(topic), 'entries', s + '.json'), JSON.stringify(full, null, 2));
  writeH(topic, s);
  const idx = join(DATA_DIR, 'index.json');
  let topics: Topic[] = [];
  try { topics = JSON.parse(readFileSync(idx, 'utf8')) as Topic[]; } catch { /* empty */ }
  const n = topic.replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
  const i = topics.findIndex(x => x.name === n);
  const nt: Topic = { name: n, head: s, entryCount: (topics[i]?.entryCount ?? 0) + 1, lastEntryAt: full.createdAt };
  if (i >= 0) topics[i] = nt; else topics.push(nt);
  mkdirSync(DATA_DIR, { recursive: true });
  writeFileSync(idx, JSON.stringify(topics, null, 2));
  return full;
}

function getE(t: string, s: string): Entry | null {
  const exact = join(nbDir(t), 'entries', s + '.json');
  try { return JSON.parse(readFileSync(exact, 'utf8')) as Entry; } catch { /* try prefix */ }
  const dir = join(nbDir(t), 'entries');
  try {
    const files = readdirSync(dir).filter(f => f.startsWith(s) && f.endsWith('.json'));
    if (files.length === 1) return JSON.parse(readFileSync(join(dir, files[0]), 'utf8')) as Entry;
  } catch { /* ignore */ }
  return null;
}

function getLog(t: string, lim = 20): Entry[] {
  let s = readH(t);
  const r: Entry[] = [];
  while (s && r.length < lim) {
    const e = getE(t, s);
    if (!e) break;
    r.push(e);
    s = e.parent ?? '';
  }
  return r;
}

function listTopics(): Topic[] {
  try { return JSON.parse(readFileSync(join(DATA_DIR, 'index.json'), 'utf8')) as Topic[]; } catch { return []; }
}

function initTopic(name: string): Topic {
  const n = name.replace(/[^a-z0-9_-]/gi, '_').toLowerCase();
  nbDir(n);
  const topics = listTopics();
  const ex = topics.find(x => x.name === n);
  if (ex) return ex;
  const nt: Topic = { name: n, head: null, entryCount: 0, lastEntryAt: null };
  topics.push(nt);
  mkdirSync(DATA_DIR, { recursive: true });
  writeFileSync(join(DATA_DIR, 'index.json'), JSON.stringify(topics, null, 2));
  return nt;
}

async function ask(pr: string): Promise<string> {
  const { createInterface } = await import('readline');
  const rl = createInterface({ input: process.stdin, output: process.stderr });
  return new Promise(res => {
    process.stderr.write(pr);
    rl.question('', a => { rl.close(); res(a); });
  });
}

// ─── CLI ─────────────────────────────────────────────────────────────────────
const prog = new Command();
prog.name('praxis').description(th.logo() + ' \u2014 Terminal client for Praxis webapp').version('2.0.0');

// auth
const auth = prog.command('auth').description('Authentication');
auth.command('login').description('Login').argument('[email]').action(async (email?: string) => {
  const c = loadCfg();
  if (!email) email = await ask('Email: ');
  const pw = await ask('Password: ');
  const sp = ora('Logging in...').start();
  try {
    const api = new Api(c);
    const r = await api.login(email, pw);
    c.token = r.token;
    c.userId = r.user?.id;
    c.userName = r.user?.name;
    saveCfg(c);
    sp.succeed(th.p('\u2713') + ' Logged in as ' + th.b(c.userName ?? email) + ' (' + c.userId?.slice(0, 8) + ')');
  } catch (e: unknown) {
    sp.fail('Login: ' + (e as Error).message);
    process.exit(1);
  }
});
auth.command('logout').action(() => {
  const c = loadCfg();
  delete c.token;
  delete c.userId;
  delete c.userName;
  saveCfg(c);
  console.log(th.p('\u2713') + ' Logged out.');
});
auth.command('status').action(() => {
  const c = loadCfg();
  console.log(th.card('Auth', [
    th.row('API', c.apiUrl),
    th.row('Token', c.token ? c.token.slice(0, 10) + '...' : th.err('none')),
    th.row('User', c.userName ?? th.dim('anon')),
  ].join('\n')));
});

// config
const cfgC = prog.command('config').description('Config');
cfgC.command('get [k]').action((k?: string) => {
  const c = loadCfg();
  if (k) console.log((c as unknown as Record<string, unknown>)[k] ?? th.dim(k + ' not set'));
  else console.log(JSON.stringify(c, null, 2));
});
cfgC.command('set <k> <v>').action((k: string, v: string) => {
  const c = loadCfg();
  (c as unknown as Record<string, unknown>)[k] = v;
  saveCfg(c);
  console.log(th.p('\u2713') + ' ' + k + ' = ' + th.b(v));
});

// dashboard
prog.command('dashboard').alias('dash').action(async () => {
  const c = loadCfg();
  const api = new Api(c);
  const sp = ora('Fetching...').start();
  try {
    const [d, pts, str] = await Promise.allSettled([api.dashboard(), api.points(), api.streak()]);
    sp.succeed();
    const dv = d.status === 'fulfilled' ? d.value : {};
    const pv = pts.status === 'fulfilled' ? pts.value : {};
    const sv = str.status === 'fulfilled' ? str.value : {};
    console.log(th.card(th.logo(), [
      th.row('User', th.b(c.userName ?? 'anon')),
      th.row('Streak', th.fire((sv as Record<string, number>)?.current_streak ?? 0)),
      th.row('Points', th.star + ' ' + String((pv as Record<string, number>)?.praxis_points ?? 0) + ' PP'),
      th.row('Goals', String((dv as Record<string, number>)?.goalCount ?? '\u2014')),
    ].join('\n')));
  } catch (e: unknown) {
    sp.warn((e as Error).message);
    const tp = listTopics();
    console.log(th.card('Local', [th.row('Topics', String(tp.length)), th.row('Dir', DATA_DIR)].join('\n')));
  }
});

// notebook
const nb = prog.command('notebook').alias('nb').description('Notebook (git-like)');

nb.command('init [t]').description('Create topic').action((t?: string) => {
  if (!t) { console.log(th.err('Usage: praxis nb init <topic>')); return; }
  const tp = initTopic(t);
  console.log(th.p('\u2713') + ' Topic ' + th.b(tp.name));
});

nb.command('list').alias('ls').description('List topics').action(() => {
  const tp = listTopics();
  if (!tp.length) { console.log(th.dim('No topics.')); return; }
  const tbl = new Table({ head: [th.b('Topic'), th.b('Entries'), th.b('HEAD'), th.b('Last')], style: { head: [] } });
  for (const t of tp) {
    tbl.push([th.b(t.name), String(t.entryCount), t.head ? t.head.slice(0, 8) : th.dim('empty'), t.lastEntryAt ? new Date(t.lastEntryAt).toLocaleDateString() : '\u2014']);
  }
  console.log(tbl.toString());
});

nb.command('log [t]').description('History (git log)').option('-n, --limit <n>', 'Limit', '20').option('--oneline', 'Compact').action((t?: string, opts?: { limit?: string; oneline?: boolean }) => {
  const topics = listTopics();
  if (!topics.length) { console.log(th.dim('No topics.')); return; }
  const topic = t ?? topics[0].name;
  const entries = getLog(topic, Number.parseInt(opts?.limit ?? '20'));
  if (!entries.length) { console.log(th.dim('No entries in "' + topic + '".')); return; }
  console.log(th.card(th.b(topic) + ' \u2014 ' + entries.length + ' entries', ''));
  if (opts?.oneline) {
    for (const e of entries) {
      console.log('  ' + th.p(e.sha.slice(0, 7)) + ' ' + e.message + ' ' + th.dim('(' + new Date(e.createdAt).toLocaleDateString() + ')'));
    }
  } else {
    for (const e of entries) {
      console.log(th.p('\u25C6') + ' ' + th.b(e.sha.slice(0, 8)) + ' ' + th.dim(new Date(e.createdAt).toLocaleString()));
      console.log('    ' + e.message);
      if (e.mood) console.log('    ' + th.dim('mood: ' + e.mood));
      if (e.parent) console.log('    ' + th.dim('parent: ' + e.parent.slice(0, 8)));
      if (e.content) console.log('    ' + th.dim(e.content.slice(0, 120)));
      console.log();
    }
  }
});

nb.command('entry <t>').alias('add').description('Add entry (git commit)').option('-m, --message <m>', 'Msg').option('--mood <m>', 'Mood').option('--content <c>', 'Content').action(async (t: string, opts?: { message?: string; mood?: string; content?: string }) => {
  const c = loadCfg();
  let msg = opts?.message ?? '';
  let content = opts?.content ?? '';
  if (!msg) msg = await ask('Message: ');
  if (!content) content = await ask('Content: ');
  if (c.token) {
    const sp = ora('Saving to webapp...').start();
    try {
      const api = new Api(c);
      await api.createEntry({ message: msg, content, mood: opts?.mood, topic: t });
      sp.succeed();
    } catch (e: unknown) {
      sp.warn('Local (API: ' + (e as Error).message + ')');
    }
  }
  const e = addEntry(t, msg, content, c.userName ?? 'anon', { mood: opts?.mood });
  console.log('\n' + th.p('\u2713') + ' ' + e.sha.slice(0, 8) + ' in ' + th.b(t));
  if (e.parent) console.log('  ' + th.dim('parent: ' + e.parent.slice(0, 8)));
});

nb.command('show <t> [s]').description('Show entry').action((t: string, s?: string) => {
  const sha = s ?? readH(t);
  if (!sha) { console.log(th.dim('No HEAD.')); return; }
  const e = getE(t, sha);
  if (!e) { console.log(th.err('Entry ' + sha + ' not found')); return; }
  console.log(th.card(e.sha.slice(0, 8) + ' \u2014 ' + new Date(e.createdAt).toLocaleString(), [
    th.row('Msg', th.b(e.message)),
    th.row('Mood', e.mood ?? th.dim('\u2014')),
    th.row('Parent', e.parent ? e.parent.slice(0, 8) : th.dim('(root)')),
    '',
    e.content ?? th.dim('(no content)'),
  ].join('\n')));
});

nb.command('tag <t> <s> <tag>').description('Tag entry').action((t: string, s: string, tag: string) => {
  const e = getE(t, s);
  if (!e) { console.log(th.err('Not found')); return; }
  if (!e.tags) e.tags = [];
  if (!e.tags.includes(tag)) e.tags.push(tag);
  writeFileSync(join(nbDir(t), 'entries', s + '.json'), JSON.stringify(e, null, 2));
  console.log(th.p('\u2713') + ' Tagged ' + th.b(s.slice(0, 8)) + ' as ' + th.b(tag));
});

nb.command('diff <t> <s1> <s2>').description('Compare entries').action((t: string, s1: string, s2: string) => {
  const e1 = getE(t, s1);
  const e2 = getE(t, s2);
  if (!e1 || !e2) { console.log(th.err('Not found')); return; }
  console.log(th.card('Diff: ' + s1.slice(0, 8) + ' \u2192 ' + s2.slice(0, 8), [
    th.row('Date 1', new Date(e1.createdAt).toLocaleString()),
    th.row('Date 2', new Date(e2.createdAt).toLocaleString()),
    th.row('Mood 1', e1.mood ?? '\u2014'),
    th.row('Mood 2', e2.mood ?? '\u2014'),
    '',
    th.b('1:'),
    e1.content ?? '(empty)',
    '',
    th.b('2:'),
    e2.content ?? '(empty)',
  ].join('\n')));
});

// goals
const gc = prog.command('goals').description('Goals');
gc.command('list').alias('ls').action(async () => {
  const c = loadCfg();
  const api = new Api(c);
  const sp = ora('Fetching...').start();
  try {
    const g = await api.goals();
    sp.succeed();
    if (!g?.length) { console.log(th.dim('No goals.')); return; }
    const tbl = new Table({ head: [th.b('Goal'), th.b('Domain'), th.b('Progress'), th.b('Status')], style: { head: [] } });
    for (const x of g.slice(0, 10)) {
      tbl.push([th.b(String(x.name ?? x.title ?? '\u2014')), String(x.domain ?? '\u2014'), th.bar(Number(x.progress ?? 0), 100), String(x.status ?? 'active')]);
    }
    console.log(tbl.toString());
  } catch (e: unknown) {
    sp.fail((e as Error).message);
  }
});
gc.command('add').option('-n, --name <n>', 'Name').action(async (opts?: { name?: string }) => {
  const c = loadCfg();
  let n = opts?.name ?? '';
  if (!n) n = await ask('Goal name: ');
  const sp = ora('Creating...').start();
  try {
    const api = new Api(c);
    await api.createGoal({ name: n });
    sp.succeed(th.p('\u2713') + ' "' + th.b(n) + '"');
  } catch (e: unknown) {
    sp.fail((e as Error).message);
  }
});

// checkin
prog.command('checkin').alias('ci').option('-n, --note <n>', 'Note').action(async (opts?: { note?: string }) => {
  const c = loadCfg();
  const sp = ora('Checking in...').start();
  try {
    const api = new Api(c);
    const r = await api.checkin(opts?.note);
    sp.succeed(th.p('\u2713') + ' Streak: ' + th.fire(r.streak ?? 0) + ' | +' + (r.points ?? 10) + ' PP');
  } catch (e: unknown) {
    sp.fail((e as Error).message);
    process.exit(1);
  }
});

// streak
prog.command('streak').action(async () => {
  const c = loadCfg();
  const api = new Api(c);
  const sp = ora('Fetching...').start();
  try {
    const s = await api.streak();
    sp.succeed();
    console.log(th.card('Streak', [
      th.row('Current', th.fire(s.current_streak ?? 0)),
      th.row('Longest', th.fire(s.longest_streak ?? 0)),
      th.row('Last', s.last_checkin_at ? new Date(s.last_checkin_at).toLocaleString() : th.dim('never')),
    ].join('\n')));
  } catch (e: unknown) {
    sp.fail((e as Error).message);
  }
});

// sync
const sc = prog.command('sync').description('Sync');
sc.command('pull').action(async () => {
  const c = loadCfg();
  if (!c.token) { console.log(th.err('Not logged in.')); process.exit(1); }
  const sp = ora('Pulling...').start();
  try {
    const api = new Api(c);
    const [gr, er] = await Promise.allSettled([api.goals(), api.journal()]);
    const goals = gr.status === 'fulfilled' ? gr.value : [];
    const entries = er.status === 'fulfilled' ? er.value : [];
    if (goals.length) {
      for (const g of goals) {
        const tp = initTopic(String(g.name ?? g.title ?? 'untitled'));
        if (g.entries) {
          for (const e of (g.entries as Array<Record<string, string>>)) {
            addEntry(tp.name, e.message ?? e.title ?? 'entry', e.content ?? '', c.userName ?? 'anon', { mood: e.mood });
          }
        }
      }
    }
    if (entries.length) {
      for (const e of entries) {
        const tp = String((e as Record<string, string>).topic ?? (e as Record<string, string>).goalId ?? 'journal');
        addEntry(tp, (e as Record<string, string>).message ?? (e as Record<string, string>).title ?? 'entry', (e as Record<string, string>).content ?? '', c.userName ?? 'anon', { mood: (e as Record<string, string>).mood });
      }
    }
    c.lastSync = new Date().toISOString();
    saveCfg(c);
    sp.succeed(th.p('\u2713') + ' Pulled ' + goals.length + ' goals, ' + entries.length + ' entries');
  } catch (e: unknown) {
    sp.fail((e as Error).message);
  }
});
sc.command('push').action(() => {
  const c = loadCfg();
  if (!c.token) { console.log(th.err('Not logged in.')); process.exit(1); }
  console.log(th.p('\u2713') + ' Entries pushed on creation.');
});

// ── bets (enhanced) ──────────────────────────────────────────────────────
const betsC = prog.command('bets').description('Accountability bets');
betsC.command('list').alias('ls').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Fetching...').start();
  try {
    const b = await api.bets(); sp.succeed();
    if (!b?.length) { console.log(th.dim('No bets.')); return; }
    const tbl = new Table({ head: [th.b('ID'), th.b('Goal'), th.b('Stake'), th.b('Deadline'), th.b('Status')], style: { head: [] } });
    for (const x of b) {
      const st = x.status === 'won' ? th.ok('\u2713') : x.status === 'lost' ? th.err('\u2717') : th.inf('active');
      tbl.push([String(x.id ?? '').slice(0, 8), th.b(String(x.goalName ?? '\u2014')), (x.stakePoints ?? 0) + ' PP', x.deadline ? new Date(x.deadline as string).toLocaleDateString() : '\u2014', st]);
    }
    console.log(tbl.toString());
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
betsC.command('add').description('Create a bet').option('-g, --goal <goal>', 'Goal name').option('-s, --stake <n>', 'Stake in PP').option('-d, --deadline <date>', 'Deadline (ISO date)').action(async (opts?: { goal?: string; stake?: string; deadline?: string }) => {
  const c = loadCfg();
  let goal = opts?.goal ?? ''; let stake = opts?.stake ?? ''; let deadline = opts?.deadline ?? '';
  if (!goal) goal = await ask('Goal name: ');
  if (!stake) stake = await ask('Stake (PP): ');
  if (!deadline) deadline = await ask('Deadline (YYYY-MM-DD): ');
  const sp = ora('Creating bet...').start();
  try {
    const api = new Api(c);
    await api.createBet({ goalName: goal, stakePoints: Number(stake), deadline: deadline + 'T23:59:59Z' });
    sp.succeed(th.p('\u2713') + ' Bet created: ' + th.b(goal) + ' for ' + stake + ' PP');
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
betsC.command('cancel <id>').description('Cancel a bet').action(async (id: string) => {
  const c = loadCfg(); const sp = ora('Canceling...').start();
  try { const api = new Api(c); await api.cancelBet(id); sp.succeed(th.p('\u2713') + ' Bet canceled'); }
  catch (e: unknown) { sp.fail((e as Error).message); }
});

// ── axiom ─────────────────────────────────────────────────────────────────
const ax = prog.command('axiom').description('Axiom AI coach');
ax.command('brief').description('Today AI brief').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Fetching brief...').start();
  try {
    const b = await api.axiomDailyBrief(); sp.succeed();
    const msg = (b as Record<string, string>)?.message ?? (b as Record<string, string>)?.brief ?? '';
    const routine = (b as Record<string, string>)?.routine ?? '';
    console.log(th.card('Axiom Daily Brief', [msg, routine ? '\n' + th.b('Routine:') + '\n' + routine : ''].join('\n')));
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
ax.command('regenerate').description('Regenerate today brief (costs 50 PP for free)').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Regenerating...').start();
  try { const r = await api.axiomRegenerate(); sp.succeed(th.p('\u2713') + ' ' + String((r as Record<string, string>)?.message ?? 'Brief regenerated')); }
  catch (e: unknown) { sp.fail((e as Error).message); }
});
ax.command('narrative').description('Weekly AI narrative').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Generating narrative...').start();
  try { const r = await api.axiomNarrative(); sp.succeed(); const msg = (r as Record<string, string>)?.narrative ?? (r as Record<string, string>)?.message ?? ''; console.log(th.card('Weekly Narrative', msg)); }
  catch (e: unknown) { sp.fail((e as Error).message); }
});
ax.command('chat [msg]').description('Chat with Axiom (costs 50 PP for free)').action(async (msg?: string) => {
  const c = loadCfg(); const api = new Api(c);
  if (!msg) msg = await ask('Axiom: ');
  const sp = ora('Thinking...').start();
  try {
    const r = await api.axiomChat(msg);
    sp.succeed();
    const reply = (r as Record<string, string>)?.reply ?? (r as Record<string, string>)?.message ?? (r as Record<string, string>)?.response ?? '';
    console.log(th.card('Axiom', reply));
  } catch (e: unknown) { sp.fail((e as Error).message); }
});

// ── messages ──────────────────────────────────────────────────────────────
const msgC = prog.command('messages').alias('msg').description('Messages');
msgC.command('view <u1> <u2>').description('View chat with user').action(async (u1: string, u2: string) => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Fetching messages...').start();
  try {
    const msgs = await api.messages(u1, u2); sp.succeed();
    if (!msgs?.length) { console.log(th.dim('No messages.')); return; }
    for (const m of msgs) {
      const from = (m.sender_id === c.userId) ? th.b('You') : th.inf(String(m.sender_name ?? 'Unknown'));
      console.log('  ' + from + ' ' + th.dim(new Date(m.created_at as string).toLocaleTimeString()) + ': ' + (m.content ?? ''));
    }
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
msgC.command('send <to>').description('Send message').option('-c, --content <c>', 'Message').action(async (to: string, opts?: { content?: string }) => {
  const c = loadCfg();
  let content = opts?.content ?? '';
  if (!content) content = await ask('Message: ');
  const sp = ora('Sending...').start();
  try {
    const api = new Api(c);
    await api.sendMessage({ receiver_id: to, content });
    sp.succeed(th.p('\u2713') + ' Message sent');
  } catch (e: unknown) { sp.fail((e as Error).message); }
});

// ── map (places) ──────────────────────────────────────────────────────────
const mapC = prog.command('map').description('Places & map');
mapC.command('list').alias('ls').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Fetching places...').start();
  try {
    const places = await api.places(); sp.succeed();
    if (!places?.length) { console.log(th.dim('No places.')); return; }
    const tbl = new Table({ head: [th.b('Name'), th.b('Type'), th.b('Members'), th.b('Lat'), th.b('Lng')], style: { head: [] } });
    for (const p of places) {
      tbl.push([th.b(String(p.name ?? '\u2014')), String(p.place_type ?? '\u2014'), String(p.member_count ?? 0), String(p.latitude ?? '\u2014'), String(p.longitude ?? '\u2014')]);
    }
    console.log(tbl.toString());
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
mapC.command('add').option('-n, --name <n>', 'Name').option('-t, --type <t>', 'Type').option('--lat <lat>', 'Latitude').option('--lng <lng>', 'Longitude').action(async (opts?: { name?: string; type?: string; lat?: string; lng?: string }) => {
  const c = loadCfg();
  let name = opts?.name ?? ''; let type = opts?.type ?? '';
  if (!name) name = await ask('Place name: ');
  if (!type) type = await ask('Type (study/gym/cafe/etc): ');
  const sp = ora('Creating place...').start();
  try {
    const api = new Api(c);
    await api.createPlace({ name, place_type: type, latitude: opts?.lat ? Number(opts.lat) : null, longitude: opts?.lng ? Number(opts.lng) : null });
    sp.succeed(th.p('\u2713') + ' Place "' + th.b(name) + '" created');
  } catch (e: unknown) { sp.fail((e as Error).message); }
});
mapC.command('join <id>').description('Join a place').action(async (id: string) => {
  const c = loadCfg(); const sp = ora('Joining...').start();
  try { const api = new Api(c); await api.joinPlace(id); sp.succeed(th.p('\u2713') + ' Joined'); }
  catch (e: unknown) { sp.fail((e as Error).message); }
});

// ── notebook pull (from webapp to local git-like store) ───────────────────
nb.command('pull [topic]').description('Pull entries from webapp').option('-t, --type <type>', 'Filter by entry_type').option('-d, --domain <domain>', 'Filter by domain').option('-s, --search <search>', 'Search content').option('-l, --limit <n>', 'Limit', '100').action(async (topic?: string, opts?: { type?: string; domain?: string; search?: string; limit?: string }) => {
  const c = loadCfg();
  if (!c.token) { console.log(th.err('Not logged in.')); process.exit(1); }
  const sp = ora('Pulling from webapp...').start();
  try {
    const api = new Api(c);
    const entries = await api.notebookEntries({ entry_type: opts?.type, domain: opts?.domain, search: opts?.search, limit: Number(opts?.limit ?? '100') });
    sp.succeed();
    if (!entries?.length) { console.log(th.dim('No entries found.')); return; }
    // Group by topic
    const grouped: Record<string, Array<Record<string, unknown>>> = {};
    for (const e of entries) {
      const tp = topic ?? String(e.topic ?? e.domain ?? e.goal_id ?? 'journal');
      if (!grouped[tp]) grouped[tp] = [];
      grouped[tp].push(e);
    }
    let total = 0;
    for (const [tp, ents] of Object.entries(grouped)) {
      initTopic(tp);
      for (const e of ents) {
        addEntry(tp, String(e.title ?? e.message ?? 'entry'), String(e.content ?? ''), c.userName ?? 'anon', {
          mood: e.mood as string | undefined,
        });
        total++;
      }
    }
    console.log(th.p('\u2713') + ' Pulled ' + th.b(String(total)) + ' entries into ' + th.b(String(Object.keys(grouped).length)) + ' topics');
    if (topic) {
      console.log('\n' + th.b('Latest entries in ' + topic + ':'));
      const log = getLog(topic, 5);
      for (const e of log) console.log('  ' + th.p(e.sha.slice(0, 7)) + ' ' + e.message + ' ' + th.dim('(' + new Date(e.createdAt).toLocaleDateString() + ')'));
    }
  } catch (e: unknown) { sp.fail((e as Error).message); }
});

nb.command('stats').description('Notebook statistics').action(async () => {
  const c = loadCfg();
  if (!c.token) { console.log(th.err('Not logged in.')); process.exit(1); }
  const sp = ora('Fetching stats...').start();
  try {
    const api = new Api(c);
    const s = await api.notebookStats();
    sp.succeed();
    console.log(th.card('Notebook Stats', [
      th.row('Total entries', String((s as Record<string, number>)?.total_entries ?? '\u2014')),
      th.row('Topics', String((s as Record<string, number>)?.unique_topics ?? '\u2014')),
      th.row('This week', String((s as Record<string, number>)?.this_week ?? '\u2014')),
      th.row('Streak', String((s as Record<string, number>)?.entry_streak ?? '\u2014')),
    ].join('\n')));
  } catch (e: unknown) { sp.fail((e as Error).message); }
});

// ── matches ───────────────────────────────────────────────────────────────
prog.command('matches').description('View your matches').action(async () => {
  const c = loadCfg(); const api = new Api(c); const sp = ora('Fetching matches...').start();
  try {
    const m = await api.matches(); sp.succeed();
    if (!m?.length) { console.log(th.dim('No matches yet.')); return; }
    const tbl = new Table({ head: [th.b('Name'), th.b('Match %'), th.b('Goal'), th.b('Streak')], style: { head: [] } });
    for (const x of m) {
      tbl.push([th.b(String(x.name ?? x.user_name ?? '\u2014')), String((x.match_score ?? x.score ?? 0) + '%'), String(x.goals ?? x.common_goals ?? '\u2014'), th.fire(Number(x.streak ?? 0))]);
    }
    console.log(tbl.toString());
  } catch (e: unknown) { sp.fail((e as Error).message); }
});

prog.parse();
