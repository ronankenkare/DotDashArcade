// Validate this project's native files with the installed Plus-C application's
// model implementation. The separate legacy plus-c CLI reads a different format.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const archive=process.env.PLUS_C_ASAR || '/Applications/Plus-C.app/Contents/Resources/app.asar';
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'dotdash-plusc-verify-'));
try {
 const data=fs.readFileSync(archive);
 const header=JSON.parse(data.subarray(16,16+data.readUInt32LE(12)).toString());
 const base=8+data.readUInt32LE(4);
 function extract(dir,prefix=''){
  for(const [name,item] of Object.entries(dir.files||{})){
   const rel=prefix?prefix+'/'+name:name;
   if(item.files)extract(item,rel);
   else if((rel.startsWith('src/model/')||rel==='src/model.js'||rel==='src/orthogonal-router.js')&&rel.endsWith('.js')){
    const out=path.join(temp,rel);fs.mkdirSync(path.dirname(out),{recursive:true});
    const start=base+Number(item.offset);fs.writeFileSync(out,data.subarray(start,start+item.size));
   }
  }
 }
 extract(header);fs.writeFileSync(path.join(temp,'package.json'),'{"type":"module"}');
 const m=await import(pathToFileURL(path.join(temp,'src/model.js')));
 const files=['project.plc',...fs.readdirSync(path.join(root,'systems')).filter(x=>x.endsWith('.plc')).map(x=>'systems/'+x)];
 const store=m.fromDocument(m.mergeProject(files.map(p=>({path:p,text:fs.readFileSync(path.join(root,p),'utf8')}))));
 const diagrams=store.ofKind('diagram').map(d=>m.normalizeDiagram(m.partsToDiagram(store,d.id)));
 for(const d of diagrams){
  for(const layer of d.layers||[]){
   if(!layer.image)continue;
   const relative=m.normalizeUiPicturePath(layer.image);
   if(!relative||!fs.existsSync(path.join(root,relative)))throw Error(`Missing UI image: ${layer.image}`);
  }
 }
 const captureManifest=path.join(root,'systems/assets/iphone-duo/manifest.json');
 if(fs.existsSync(captureManifest)){
  const capture=JSON.parse(fs.readFileSync(captureManifest,'utf8'));
  for(const shot of capture.screenshots){
   const bytes=fs.readFileSync(path.join(root,shot.path));
   if(crypto.createHash('sha256').update(bytes).digest('hex')!==shot.sha256)throw Error(`Screenshot changed: ${shot.path}`);
   if(bytes.readUInt32BE(16)!==shot.pixels[0]||bytes.readUInt32BE(20)!==shot.pixels[1])throw Error(`Screenshot dimensions changed: ${shot.path}`);
  }
 }
 const findings=diagrams.flatMap(d=>m.validateDiagram(d).map(f=>({diagram:d.title,...f}))).concat(m.validateTraces(store));
 const unexpected=findings.filter(x=>!(x.level==='warning'&&x.title==='No requirements'&&diagrams.some(d=>d.title===x.diagram&&d.diagramType==='requirements')));
 if(unexpected.length)throw Error(JSON.stringify(unexpected,null,2));
 // Whole-file baselines use SHA-256. Symbol parts use the Plus-C editor's line hash,
 // so a moved or edited part fails here and is flagged in the app's code gutter.
 const codeParts=store.all().filter(m.isCodeArtifact);
 for(const a of codeParts){
  const file=fs.readFileSync(path.join(root,a.properties.path));
  const range=m.codeArtifactRange(a);
  if(!range){
   const hash=crypto.createHash('sha256').update(file).digest('hex');
   if(hash!==a.properties.contentHash)throw Error(`Source changed; review affected models: ${a.properties.path}`);
   continue;
  }
  const lines=file.toString('utf8').split('\n');
  const name=a.properties.symbol.split('.').pop();
  if(!lines[range.startLine-1]?.includes(name))throw Error(`Traced symbol moved; re-anchor ${a.name} (line ${range.startLine})`);
  if(m.shortHash(lines.slice(range.startLine-1,range.endLine).join('\n'))!==a.properties.contentHash)throw Error(`Traced code changed; review ${a.name} and its traces`);
 }
 const symbolTraces=store.all().filter(t=>t.kind==='implements'&&m.codeArtifactRange(store.get(t.sourceId)));
 const {files:parts}=m.splitProject(store,{defaultDirectory:'systems'});
 const copy=m.fromDocument(m.mergeProject([...parts].map(([p,d])=>({path:p,text:m.serializePart(d)}))));
 const ids=s=>JSON.stringify(s.all().map(e=>e.id).sort());
 if(ids(copy)!==ids(store)||copy.allViews().length!==store.allViews().length)throw Error('Native round trip changed elements or views');
 // Traceability is layered: need ← system requirement ← component requirement ← code and tests.
 // Each level traces only to the level directly above it.
 const reqs=store.ofKind('document-requirement');
 const level=r=>/^NEED-/.test(r?.properties?.key)?'need':/^REQ-/.test(r?.properties?.key)?'system':/^CMP-/.test(r?.properties?.key)?'component':null;
 const needs=reqs.filter(r=>level(r)==='need'),system=reqs.filter(r=>level(r)==='system'),component=reqs.filter(r=>level(r)==='component');
 if(needs.length+system.length+component.length!==reqs.length)throw Error('Requirement keys must start NEED-, REQ- or CMP-');
 if(!needs.length||!system.length||!component.length)throw Error('Each requirement level needs at least one requirement');
 const traces=store.all().filter(m.isTraceRelationship);
 const into=(r,kind,from)=>traces.filter(t=>t.targetId===r.id&&t.kind===kind&&from(store.get(t.sourceId)));
 const outOf=(r,kind,to)=>traces.filter(t=>t.sourceId===r.id&&t.kind===kind&&to(store.get(t.targetId)));
 const isLevel=l=>e=>level(e)===l;
 for(const r of system)if(!outOf(r,'refines',isLevel('need')).length)throw Error(`System requirement refines no need: ${r.name}`);
 for(const r of needs)if(!into(r,'refines',isLevel('system')).length)throw Error(`Need is refined by no system requirement: ${r.name}`);
 for(const r of component)if(!outOf(r,'refines',isLevel('system')).length)throw Error(`Component requirement derives from no system requirement: ${r.name}`);
 for(const r of system)if(!into(r,'refines',isLevel('component')).length)throw Error(`System requirement has no component requirements: ${r.name}`);
 for(const r of system)if(!into(r,'satisfies',m.isDiagramEndpoint).length)throw Error(`System requirement lacks design view: ${r.name}`);
 const architecture=store.ofKind('diagram').find(d=>d.name==='07 Software Architecture');
 const shownIn07=e=>e?.kind==='class'&&store.viewsOf(e.id).some(v=>v.diagramId===architecture.id);
 for(const r of component)if(!into(r,'satisfies',shownIn07).length)throw Error(`Component requirement is not allocated to an architecture class: ${r.name}`);
 const isTest=a=>m.isCodeArtifact(a)&&/^dot-dash(UI)?Tests\//.test(a.properties.path);
 const isAppCode=a=>m.isCodeArtifact(a)&&!isTest(a);
 for(const r of component)if(!into(r,'implements',a=>isAppCode(a)&&m.codeArtifactRange(a)).length)throw Error(`Component requirement has no implementing code: ${r.name}`);
 for(const t of traces){
  const s=store.get(t.sourceId),g=store.get(t.targetId);
  if(m.isCodeArtifact(s)&&['need','system'].includes(level(g))&&t.kind==='implements')throw Error(`Code skips a level: ${s.name} implements ${g.name}`);
  if(m.isCodeArtifact(s)&&level(g)==='need')throw Error(`Code traces to a stakeholder need: ${s.name}`);
  if(level(s)==='component'&&level(g)==='need')throw Error(`Component requirement skips a level: ${s.name}`);
 }
 const appClasses=[...new Set(store.viewsIn(architecture.id).map(v=>store.get(v.elementId)))].filter(e=>e?.kind==='class'&&!/service/i.test(e.properties.stereotype));
 for(const c of appClasses)if(!symbolTraces.some(t=>t.targetId===c.id))throw Error(`Architecture class lacks code trace: ${c.name}`);
 // Verification coverage is reported, not enforced: gaps are listed in the verification plan.
 const verifies=r=>into(r,'refines',a=>isTest(a)&&m.codeArtifactRange(a));
 const unitVerified=component.filter(r=>verifies(r).length);
 const systemVerified=system.filter(r=>verifies(r).length);
 const symbolParts=codeParts.filter(a=>m.codeArtifactRange(a));
 console.log(`Validated ${diagrams.length} native views/documents, ${reqs.length} requirements, source hashes and split/merge round trip. ${findings.length} expected prose warnings.`);
 console.log(`Layered traceability: ${needs.length} needs ← ${system.length} system ← ${component.length} component requirements; every level traces only to the one above.`);
 console.log(`Code: ${symbolParts.filter(isAppCode).length} app parts implement all ${component.length} component requirements and ${appClasses.length} app classes; ${symbolParts.filter(isTest).length} test parts.`);
 console.log(`Verification (inspected, not executed): ${unitVerified.length}/${component.length} component and ${systemVerified.length}/${system.length} system requirements have test traces.`);
} finally {fs.rmSync(temp,{recursive:true,force:true});}
