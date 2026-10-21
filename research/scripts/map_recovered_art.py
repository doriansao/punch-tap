from pathlib import Path
import json
root=Path('research/evidence/animation');d=json.loads((root/'measurements.json').read_text())
player={0:24,1:25,2:26,3:27,4:28,5:8,6:8,7:24,8:9,9:25,10:10,11:24,12:11,13:25,14:16,15:16,16:17,17:17,18:25,19:24,20:19,21:20,22:20,23:16,24:17,25:21,26:21,27:21,28:24,29:19,30:20,31:22,32:22,33:22,34:28,35:12,36:12,37:12,38:12,39:12,40:19,41:20,42:13,43:23,44:23,45:23,46:23,47:14,48:14,49:29,50:29,51:14,52:35,53:35,54:15,55:15,56:15,57:15,58:15,59:14,60:15,61:15,62:15,63:15,64:24,65:24,66:24,67:24,68:24,69:24,70:24,71:25,72:24,73:25,74:24,75:25,76:24,77:25,78:24,79:25,80:24,81:25,82:24,83:25,84:24,85:32,86:33,87:34,88:24,89:14,90:14,91:35,92:35,93:24,94:30,95:31,96:10,97:11}
opp={0:24,1:25,2:16,3:17,4:26,5:18,6:19,7:27,8:28,9:29,10:28,11:27,12:8,13:9,14:20,15:11,16:11,17:21,18:13,19:14,20:22,21:23,22:27,23:15,24:30,25:31,26:31,27:11,28:11,29:11,30:18,31:18,32:15,33:24,34:26,35:25,36:27,37:10}
player.update({68:36,69:37,70:38,71:39})
opp.update({8:38,10:38,22:39,36:39,38:32,39:33,40:34,41:35,42:36,43:11,44:11,45:19,46:19,47:37})
errors=[];count=0
for case,t in d.items():
 for row in t['frames']:
  p=row['player'];o=row['opponent'];pose=int(p.get('display_pose',p['pose']));p['art_frame']=player.get(pose,24);p['art_flip']=pose in [16,17,24,31,32,33,54,55,56,57];o['art_frame']=opp.get(o.get('visual_pose_id',-1),24);o['art_flip']=o.get('visual_pose_id',-1)in[5,16,30,31,43,44]
  if p['box'] and pose not in player and p.get('ppu_mask_difference',1)==0:errors.append([case,row['frame'],pose])
  count+=1
(root/'measurements.json').write_text(json.dumps(d,separators=(',',':')))
Path('assets/data/pose_art_map.json').write_text(json.dumps({'player':player,'opponent':opp,'player_flip':[16,17,24,31,32,33,54,55,56,57],'opponent_flip':[5,16,30,31,43,44]},indent=2))
print('Mapped',count,'paired samples; unmapped verified player shapes',errors[:20])
