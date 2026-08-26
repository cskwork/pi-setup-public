# Verifying the built map

Build fully, inspect once in a batched round, fix everything it shows in one pass,
confirm with at most one more round. Do not loop.

## Serve it

`file://` is blocked by some browser-tool security guards. Serve over HTTP:

```bash
mkdir -p /tmp/spm && cp <target>.html /tmp/spm/index.html
cd /tmp/spm && (python3 -m http.server 8791 >/dev/null 2>&1 &)
sleep 1.5 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8791/
```

Clean up the server and the temp copy when finished.

## One batched probe

Run these together, not as separate trips.

**Structure and overflow**

```js
var p=document.querySelector('.pane'),lim=p.getBoundingClientRect().right,bad=[];
document.querySelectorAll('.pane *').forEach(function(e){
  var r=e.getBoundingClientRect();
  if(r.right>lim+1) bad.push(e.tagName+'.'+(e.className||'')+' w='+Math.round(r.width));
});
JSON.stringify({overflow:p.scrollWidth>p.clientWidth,offenders:bad.slice(0,10)})
```

**Broken tree links**

```js
var missing=[];
document.querySelectorAll('.tree a').forEach(function(a){
  if(!document.getElementById(a.getAttribute('href').slice(1))) missing.push(a.getAttribute('href'));
});
JSON.stringify({links:document.querySelectorAll('.tree a').length,broken:missing})
```

**Highlight, both granularities**

```js
function hit(sel){
  document.querySelector('.tree a[href="'+sel+'"]').click();
  var el=document.querySelector(sel), sec=el.tagName==='SECTION'?el:el.closest('section');
  return {sel:sel,tag:el.tagName,elLit:el.classList.contains('lit'),secLit:sec.classList.contains('lit')};
}
JSON.stringify([hit('#m1-avg'),hit('#batch')])
```

**Contrast is untouched while lit** — the whole point of additive emphasis:

```js
document.querySelector('.tree a[href="#v1"]').click();
var lit=getComputedStyle(document.querySelector('#v1 p.lead')).color;
var un =getComputedStyle(document.querySelector('#origin p.lead')).color;
JSON.stringify({lit:lit,unlit:un,safe:lit===un})
```

`safe` must be `true`. If it is false, the highlight is stealing contrast and the
ratios you computed no longer hold.

**Both themes** — toggle and repeat the rail/row probes:

```js
document.getElementById('themeBtn').click();
JSON.stringify({theme:document.documentElement.dataset.theme})
```

**True wraps only** — intentional `<br>` separators are not defects:

```js
var real=[];
document.querySelectorAll('.src').forEach(function(e){
  var lh=parseFloat(getComputedStyle(e).lineHeight);
  var lines=Math.round(e.getBoundingClientRect().height/lh), brs=e.querySelectorAll('br').length;
  if(lines>brs+1) real.push(e.textContent.trim().slice(0,44));
});
JSON.stringify({trueWraps:real.length,samples:real})
```

## Content check

Mechanical checks cannot catch these. Read for them.

- Does every claim carry a `file:line`?
- Is every inference labeled `추정`?
- Does the 미확인 list name what you actually skipped?
- Does the module comparison table cover every module in both roles?
- For each asymmetric module, is there a code reason, not a guess?
- Do numbers carry their denominator?

## Known trap

A batch-backed value with a fallback that fires **only on zero rows** will serve
stale data indefinitely once the batch stops, with no signal. Whenever you find a
snapshot read, find its fallback condition and state this explicitly. It is a
recurring silent-failure shape, not a one-off.
