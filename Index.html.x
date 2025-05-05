
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>原物料管理（含QR掃描）</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
<script src="https://unpkg.com/html5-qrcode@2.3.8/minified/html5-qrcode.min.js"></script>
<style>
body{padding:2rem}
.table-responsive{max-height:50vh;overflow-y:auto}
.report-border td,.report-border th{border:1px solid #000;padding:4px;text-align:center}
.report-title{font-weight:bold;font-size:1.25rem;text-align:center;margin-bottom:1rem}
.signature-line{height:40px;border-bottom:1px solid #000;width:160px;display:inline-block;margin-left:.5rem;margin-right:1.5rem}
#reader{width:100%;margin-bottom:1rem}
</style>
</head>
<body>
<h2>原物料管理（含QR掃描）</h2>
<form id="matForm" class="row g-3 align-items-end">
 <div class="col-md-3"><label class="form-label">日期</label><input id="matDate" type="date" class="form-control" required></div>
 <div class="col-md-3"><label class="form-label">料號</label><input id="matCode" type="text" class="form-control"></div>
 <div class="col-md-3"><label class="form-label">品項</label><input id="matItem" type="text" class="form-control" required></div>
 <div class="col-md-2"><label class="form-label">儲位</label><input id="matLoc" type="text" class="form-control"></div>
 <div class="col-md-2"><label class="form-label">進料量(+)</label><input id="matIn" type="number" step="any" class="form-control" value="0"></div>
 <div class="col-md-2"><label class="form-label">領料量(-)</label><input id="matOut" type="number" step="any" class="form-control" value="0"></div>
 <div class="col-md-2 d-grid"><button class="btn btn-primary" type="submit">新增/更新</button></div>
</form>

<hr>
<h5>使用手機鏡頭掃描 QR Code（將填入品項名稱）</h5>
<select id="cameraSelect" class="form-select w-auto mb-2"></select>
<div id="reader"></div>
<div class="mb-3">
 <button class="btn btn-outline-secondary btn-sm" onclick="startScanner()">啟動掃描器</button>
 <button class="btn btn-outline-danger btn-sm" onclick="stopScanner()">停止掃描器</button>
</div>
<div id="qrError" class="text-danger mb-3"></div>

<div class="table-responsive mt-4">
<table id="matTable" class="table table-sm table-striped">
 <thead class="table-light"><tr><th>日期</th><th>料號</th><th>品項</th><th>儲位</th><th>進料量</th><th>領料量</th><th>庫存量</th></tr></thead>
 <tbody></tbody>
</table>
</div>

<div class="d-flex gap-2 my-3">
 <input id="reportDate" type="date" class="form-control w-auto">
 <button id="exportPdf" class="btn btn-danger">匯出 PDF</button>
 <button id="exportXls" class="btn btn-success">匯出 Excel</button>
</div>

<div id="reportContainer" style="display:none;"></div>

<script>
let data=[], qrScanner=null;

document.getElementById('matForm').addEventListener('submit',e=>{
 e.preventDefault();
 const d=matDate.value;
 const code=matCode.value.trim();
 const it=matItem.value.trim();
 const loc=matLoc.value.trim();
 const qIn=parseFloat(matIn.value)||0;
 const qOut=parseFloat(matOut.value)||0;
 const stock=data.filter(r=>r.item===it&&r.date<=d).reduce((a,c)=>a+c.in-c.out,0)+qIn-qOut;
 data.push({date:d,code:code,item:it,loc:loc,in:qIn,out:qOut,stock});
 render();
 e.target.reset();matDate.focus();
});

function render(){
 const tbody=document.querySelector('#matTable tbody');
 tbody.innerHTML='';
 data.sort((a,b)=>new Date(a.date)-new Date(b.date)).forEach(r=>{
  tbody.insertAdjacentHTML('beforeend',`<tr><td>${r.date}</td><td>${r.code||""}</td><td>${r.item}</td><td>${r.loc||""}</td><td>${r.in}</td><td>${r.out}</td><td>${r.stock}</td></tr>`);
 });
}

document.getElementById('exportPdf').addEventListener('click',()=>{
 const d=reportDate.value;if(!d){alert('請先選擇日期');return;}
 const daily=data.filter(r=>r.date===d);
 if(!daily.length){alert('無該日資料');return;}
 let html='<div class="report-title">每日原物料管理表</div><p>日期：'+d+'</p>';
 html+='<table class="report-border" width="100%"><thead><tr><th>料號</th><th>品項</th><th>儲位</th><th>進料量</th><th>領料量</th><th>結餘</th></tr></thead><tbody>';
 daily.forEach(r=>{
   html+=`<tr><td>${r.code||""}</td><td>${r.item}</td><td>${r.loc||""}</td><td>${r.in}</td><td>${r.out}</td><td>${r.stock}</td></tr>`;
 });
 html+='</tbody></table><div class="mt-4"><span>管理人</span><span class="signature-line"></span><span>單位主管</span><span class="signature-line"></span></div>';
 const cont=document.getElementById("reportContainer");cont.innerHTML=html;cont.style.display='block';
 html2pdf().from(cont).set({margin:.3,filename:'Material_'+d+'.pdf',image:{type:'jpeg',quality:.98},html2canvas:{scale:2},jsPDF:{unit:'in',format:'a4'}}).save().then(()=>{cont.style.display='none';});
});

document.getElementById('exportXls').addEventListener('click',()=>{
 const wb=XLSX.utils.book_new();
 const ws=XLSX.utils.json_to_sheet(data.map(r=>({
   日期: r.date,
   料號: r.code || "",
   品項: r.item,
   儲位: r.loc || "",
   進料量: r.in,
   領料量: r.out,
   庫存量: r.stock
 })));
 XLSX.utils.book_append_sheet(wb,ws,'Materials');
 XLSX.writeFile(wb,'material_data.xlsx');
});

async function startScanner(){
 stopScanner();
 try {
  const cameras = await Html5Qrcode.getCameras();
  if (cameras.length === 0) throw "未偵測到鏡頭";
  const selectedId = document.getElementById("cameraSelect").value || cameras[0].id;
  qrScanner = new Html5Qrcode("reader");
  await qrScanner.start(selectedId, { fps: 10, qrbox: 250 },
   (decodedText) => {
    matItem.value = decodedText;
    stopScanner();
   },
   (err) => {}
  );
 } catch (err) {
  document.getElementById("qrError").innerText = "無法啟動鏡頭：" + err;
 }
}

function stopScanner(){
 if (qrScanner) {
  qrScanner.stop().then(() => qrScanner.clear()).catch(()=>{});
  qrScanner = null;
 }
}

Html5Qrcode.getCameras().then(devices => {
 const sel = document.getElementById("cameraSelect");
 sel.innerHTML = devices.map(d=>`<option value="${d.id}">${d.label}</option>`).join('');
});
</script>
</body>
</html>
