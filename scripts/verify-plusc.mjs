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
 for(const a of store.all().filter(m.isCodeArtifact)){
  const hash=crypto.createHash('sha256').update(fs.readFileSync(path.join(root,a.properties.path))).digest('hex');
  if(hash!==a.properties.contentHash)throw Error(`Source changed; review affected models: ${a.properties.path}`);
 }
 const {files:parts}=m.splitProject(store,{defaultDirectory:'systems'});
 const copy=m.fromDocument(m.mergeProject([...parts].map(([p,d])=>({path:p,text:m.serializePart(d)}))));
 const ids=s=>JSON.stringify(s.all().map(e=>e.id).sort());
 if(ids(copy)!==ids(store)||copy.allViews().length!==store.allViews().length)throw Error('Native round trip changed elements or views');
 const reqs=store.ofKind('document-requirement');
 if(reqs.length!==12)throw Error(`Expected 12 requirements, found ${reqs.length}`);
 for(const r of reqs)if(!store.all().some(t=>m.isTraceRelationship(t)&&t.targetId===r.id&&t.kind==='satisfies'))throw Error(`Requirement lacks design trace: ${r.name}`);
 console.log(`Validated ${diagrams.length} native views/documents, ${reqs.length} requirements, source hashes and split/merge round trip. ${findings.length} expected prose warnings.`);
} finally {fs.rmSync(temp,{recursive:true,force:true});}
