"""Install and validate in a simulator only. Never targets a physical device."""
from pathlib import Path
import json, subprocess, sys, time, shutil, os
root=Path(__file__).resolve().parents[1]
simulator=sys.argv[1]
app=root/'build/Simulator/Blasterball.app'
bundle='com.wireproof.blasterball.prototype'
out=root/'build'/f'verification-{simulator}'
out.mkdir(exist_ok=True)
def sim(*args):
 if len(args)>2 and args[0]=='io' and args[2]=='screenshot' and os.environ.get('BB_SIM_DISPLAY'):
  args=(*args[:3], '--display='+os.environ['BB_SIM_DISPLAY'], *args[3:])
 return subprocess.check_output(['xcrun','simctl',*args],text=True).strip()
sim('install',simulator,str(app))
sim('launch','--terminate-running-process',simulator,bundle)
time.sleep(2)
sim('io',simulator,'screenshot','/tmp/bb-library-'+simulator+'.png')
shutil.copy2('/tmp/bb-library-'+simulator+'.png',out/'library.png')
results={}
for edition in ['revolution','remix','holidays','bb3']:
 launched_at=time.time()
 sim('launch','--terminate-running-process',simulator,bundle,'--edition',edition,'--smoke-test','--audio-check')
 time.sleep(2)
 container=Path(sim('get_app_container',simulator,bundle,'data'))
 for name in ['smoke-test.json',f'audio-check-{edition}.json']:
  source=container/'Documents'/name
  for attempt in range(30):
   if source.exists() and source.stat().st_mtime>=launched_at: break
   time.sleep(1)
  assert source.exists() and source.stat().st_mtime>=launched_at, (edition,"fresh result missing",str(source))
  value=json.loads(source.read_text())
  shutil.copy2(source,out/f'{edition}-{name}')
  assert value['passed'], (edition,name,value)
  results[f'{edition}:{name}']=value
 sim('io',simulator,'screenshot','/tmp/bb-'+edition+'-'+simulator+'.png')
 shutil.copy2('/tmp/bb-'+edition+'-'+simulator+'.png',out/f'{edition}.png')
(out/'summary.json').write_text(json.dumps(results,indent=2)+'\n')
print('Simulator validation passed:',out)
