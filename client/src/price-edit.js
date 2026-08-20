import { supabase } from './supabase';

const money = v => v == null ? '—' : new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(v);

async function getCurrentProfile(){
  const { data:{ user } } = await supabase.auth.getUser();
  if(!user) return null;
  const { data } = await supabase.from('profiles').select('*').eq('id',user.id).single();
  return data ? { ...data, authId:user.id } : null;
}

function styleBox(box){
  box.style.cssText='margin-top:14px;padding:14px;border:1px solid #dfe5ed;border-radius:10px;background:#f8fafc';
  box.innerHTML=`<div style="font-weight:800;margin-bottom:10px">✏️ Atualizar preço</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <label style="display:block;font-size:12px;font-weight:700">À vista<input data-edit-cash type="number" step="0.01" style="display:block;width:100%;margin-top:6px;border:1px solid #dfe5ed;border-radius:9px;padding:10px"></label>
      <label style="display:block;font-size:12px;font-weight:700">A prazo<input data-edit-credit type="number" step="0.01" style="display:block;width:100%;margin-top:6px;border:1px solid #dfe5ed;border-radius:9px;padding:10px"></label>
    </div>
    <label style="display:block;font-size:12px;font-weight:700;margin-top:10px">Distribuidor<input data-edit-distributor style="display:block;width:100%;margin-top:6px;border:1px solid #dfe5ed;border-radius:9px;padding:10px"></label>
    <div style="display:flex;gap:8px;margin-top:10px"><button data-edit-save>Salvar novo preço</button><button data-edit-cancel class="ghost">Cancelar</button></div>`;
}

async function enhance(){
  const profile=await getCurrentProfile();
  if(!profile || profile.role==='vendedor') return;
  document.querySelectorAll('.detail').forEach(async detail=>{
    if(detail.querySelector('[data-price-editor]')) return;
    const row=detail.closest('tr')?.previousElementSibling;
    const status=row?.querySelector('.status')?.textContent?.trim();
    if(status!=='Aguardando decisão') return;
    const title=detail.querySelector('h3')?.textContent?.trim();
    if(!title) return;
    const parts=title.split(' • ');
    const code=parts[0]?.trim(), brand=parts.slice(1).join(' • ').trim();
    if(!code||!brand) return;
    const {data:q,error}=await supabase.from('quotes').select('id,cash,credit,distributor,status').eq('code',code).eq('brand',brand).eq('status','AGUARDANDO_DECISAO').order('created_at',{ascending:false}).limit(1).maybeSingle();
    if(error||!q) return;
    const editor=document.createElement('div'); editor.dataset.priceEditor='1'; styleBox(editor);
    editor.querySelector('[data-edit-cash]').value=q.cash??'';
    editor.querySelector('[data-edit-credit]').value=q.credit??'';
    editor.querySelector('[data-edit-distributor]').value=q.distributor??'';
    detail.appendChild(editor);
    editor.querySelector('[data-edit-cancel]').onclick=()=>editor.remove();
    editor.querySelector('[data-edit-save]').onclick=async()=>{
      const cash=Number(editor.querySelector('[data-edit-cash]').value);
      const credit=Number(editor.querySelector('[data-edit-credit]').value);
      const distributor=editor.querySelector('[data-edit-distributor]').value.trim();
      if(!distributor) return alert('Informe o distribuidor.');
      if(!Number.isFinite(cash)||!Number.isFinite(credit)) return alert('Informe os dois preços.');
      const {data:latest,error:checkError}=await supabase.from('quotes').select('status,cash,credit').eq('id',q.id).single();
      if(checkError) return alert(checkError.message);
      if(latest.status!=='AGUARDANDO_DECISAO') return alert('Esta cotação já foi concluída e não pode mais ser alterada.');
      const {error:updateError}=await supabase.from('quotes').update({cash,credit,distributor}).eq('id',q.id).eq('status','AGUARDANDO_DECISAO');
      if(updateError) return alert(updateError.message);
      const {data:{user}}=await supabase.auth.getUser();
      await supabase.from('quote_history').insert({quote_id:q.id,user_id:user.id,action:'Preço atualizado',details:`De ${money(latest.cash)} / ${money(latest.credit)} para ${money(cash)} / ${money(credit)} • Distribuidor: ${distributor}`});
      alert('Preço atualizado com sucesso. O vendedor já verá o novo valor.');
      location.reload();
    };
  });
}

const observer=new MutationObserver(()=>enhance());
observer.observe(document.body,{childList:true,subtree:true});
setTimeout(enhance,800);
