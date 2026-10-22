"""Local-only Godot checks. Never invokes GitHub or a hosted runner."""
from pathlib import Path
import argparse, subprocess, sys

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--godot',default='G:/Programming/Tools/Godot/Godot_v4.7.2-stable_mono_win64_console.exe')
p.add_argument('--evidence',action='store_true',help='Include tests requiring ignored local ROM captures')
args=p.parse_args()
logs=root/'research/evidence/local_validation';logs.mkdir(parents=True,exist_ok=True)
tests=['controller_input_test','animation_machine_test','knockdown_flow_test','first_bout_test','ui_test','entrance_flow_test','punch_registration_test','pose_family_registration_test']
if args.evidence:tests+=['contact_vm_test','fight_control_test','opponent_compositor_test','knockdown_entry_test','presentation_gate_test','entrance_step_test','presentation_control_test','coupled_fight_test','full_fight_parity_test','referee_presentation_test','impact_presentation_test','body_fight_parity_test','body_counter_parity_test','getup_fight_parity_test','defense_fight_parity_test','attack_cue_test','referee_speech_test','referee_partial_test','getup_finish_parity_test','round2_parity_test','round_return_setup_test','ring_projection_test']
failed=[]
for test in tests:
    command=[args.godot,'--headless','--path',str(root),'--script',f'res://tests/{test}.gd']
    with (logs/f'{test}.log').open('w',encoding='utf-8') as out:
        try:result=subprocess.run(command,stdout=out,stderr=subprocess.STDOUT,timeout=60,cwd=root)
        except subprocess.TimeoutExpired:
            failed.append(test);print('TIMEOUT',test,flush=True);continue
    if result.returncode:failed.append(test)
    print(('FAIL' if result.returncode else 'PASS'),test,flush=True)
result=subprocess.run([sys.executable,'tools/check_atlas_geometry.py'],cwd=root)
if result.returncode:failed.append('atlas geometry')
result=subprocess.run([sys.executable,'tools/check_docs.py'],cwd=root)
if result.returncode:failed.append('docs')
print('Local validation:',len(failed),'failures;',logs)
sys.exit(bool(failed))
