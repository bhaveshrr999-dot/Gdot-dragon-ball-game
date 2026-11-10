"""Original project assets using Blender's open-source Python API. No downloaded models."""
from pathlib import Path
import math, random
import bpy
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
OUT.mkdir(exist_ok=True)

def material(name, color):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*color,1)
    m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8
    return m

def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)

reset(); random.seed(841)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1)
rock=bpy.context.object;rock.name='StratifiedRock'
for v in rock.data.vertices:
    v.co *= random.uniform(.83,1.17)
    v.co.z=max(0,v.co.z*1.6+.8)
rock.data.materials.append(material('Sandstone',(.31,.22,.15)))
rock.data.materials.append(material('WeatheredFace',(.48,.34,.22)))
for face in rock.data.polygons: face.material_index=1 if face.center.z>.7 else random.randrange(2)
bpy.ops.export_scene.gltf(filepath=str(OUT/'wasteland_rock.glb'),export_format='GLB')

for warrior in ['goku','vegeta']:
    reset(); pieces=[]; hair_groups={}; extras=[]
    skin=material('Skin',(.68,.38,.22)); cloth=material('Costume',(.92,.22,.035) if warrior=='goku' else (.025,.12,.42))
    navy=material('BlueTrim',(.015,.04,.16));white=material('Armor',(.85,.85,.78));hair=material('Hair',(.015,.012,.025));brows=material('Brows',(.015,.012,.025));black=material('Iris',(.008,.01,.02));ink=material('Ink',(.008,.01,.02));gold=material('ArmorGold',(.65,.46,.13))
    def part(name, pos, scale, mat, bone):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=pos)
        obj=bpy.context.object;obj.name=name;obj.scale=scale
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        obj.data.materials.append(mat)
        for f in obj.data.polygons:f.use_smooth=True
        group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        pieces.append(obj);return obj
    def loft(name, rings, mat, bone, center=(0,0), segments=12):
        verts=[];faces=[]
        for z,rx,ry in rings:
            for i in range(segments):
                angle=i*math.tau/segments
                verts.append((center[0]+math.cos(angle)*rx,center[1]+math.sin(angle)*ry,z))
        for row in range(len(rings)-1):
            for i in range(segments):
                j=(i+1)%segments;a=row*segments;b=(row+1)*segments
                faces.append((a+i,a+j,b+j,b+i))
        faces.extend([tuple(reversed(range(segments))),tuple((len(rings)-1)*segments+i for i in range(segments))])
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
        mesh.materials.append(mat);g=obj.vertex_groups.new(name=bone);g.add(list(range(len(verts))),1,'REPLACE');pieces.append(obj)
        return obj
    def panel(name, vertices, mat, bone):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],[tuple(range(len(vertices)))]);mesh.update()
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
        mesh.materials.append(mat);g=obj.vertex_groups.new(name=bone);g.add(list(range(len(vertices))),1,'REPLACE');pieces.append(obj)
        return obj
    loft('TailoredTorso',[(1.28,.29,.19),(1.43,.33,.21),(1.76,.42,.235),(1.98,.43,.22),(2.09,.28,.16)],cloth,'spine')
    part('Belt',(0,0,1.29),(.41,.255,.09),navy if warrior=='goku' else gold,'hips')
    part('Neck',(0,0,2.19),(.13,.13,.16),skin,'head')
    part('Head',(0,0,2.45),(.27,.235,.29),skin,'head')
    part('Jaw',(0,.09,2.29),(.21,.20,.17),skin,'head')
    part('Nose',(0,.27,2.41),(.045,.07,.07),skin,'head')
    for side in [-1,1]:
        suffix='L' if side<0 else 'R'
        part('Eye'+suffix,(side*.11,.238,2.48),(.082,.035,.047),white,'eye'+suffix)
        part('Pupil'+suffix,(side*.11,.272,2.48),(.025,.014,.035),black,'eye'+suffix)
        brow=part('Brow'+suffix,(side*.11,.26,2.54),(.10,.025,.022),brows,'head');brow.rotation_euler.y=side*-.22
        part('UpperArm'+suffix,(side*.53,0,1.86),(.17,.18,.30),skin if warrior=='goku' else cloth,'arm'+suffix)
        part('Forearm'+suffix,(side*.56,.025,1.43),(.13,.15,.25),skin if warrior=='goku' else cloth,'forearm'+suffix)
        part('Wrist'+suffix,(side*.56,.025,1.26),(.14,.16,.085),navy if warrior=='goku' else white,'forearm'+suffix)
        hand_mat=skin if warrior=='goku' else white
        part('Palm'+suffix,(side*.56,.035,1.14),(.11,.095,.11),hand_mat,'hand'+suffix)
        for finger in range(4):
            x=side*.56+(finger-1.5)*.05
            part('Finger'+str(finger)+suffix,(x,.06,1.00),(.024,.035,.10),hand_mat,'finger'+str(finger)+suffix)
        part('Thumb'+suffix,(side*.69,.06,1.14),(.045,.045,.08),hand_mat,'thumb'+suffix)
        loft('GiLeg'+suffix,[(.59,.155,.16),(.85,.19,.20),(1.10,.19,.21),(1.22,.16,.19)],cloth,'thigh'+suffix,(side*.21,0))
        part('Shin'+suffix,(side*.23,0,.42),(.15,.17,.30),cloth,'shin'+suffix)
        part('Boot'+suffix,(side*.23,.075,.18),(.17,.26,.18),navy if warrior=='goku' else white,'foot'+suffix)
    if warrior=='vegeta':
        loft('ChestArmor',[(1.45,.32,.22),(1.62,.36,.25),(1.92,.44,.25),(2.06,.32,.19)],white,'spine',(0,.06))
        for z in [1.47,1.53,1.59]:
            panel('ArmorRib',[(-.25,.32,z),(.25,.32,z),(.25,.32,z+.045),(-.25,.32,z+.045)],gold,'spine')
    else:
        panel('Undershirt',[(-.22,.215,2.10),(.22,.215,2.10),(0,.282,1.73)],navy,'spine')
    panel('Mouth',[(-.07,.278,2.28),(.07,.278,2.28),(.055,.279,2.267),(-.055,.279,2.267)],ink,'head')
    if warrior=='vegeta':
        begin=len(pieces)
        points=[(-.09,2.58),(-.09,2.66),(0,2.60),(.09,2.66),(.09,2.58)]
        for (x1,z1),(x2,z2) in zip(points,points[1:]):
            dx=x2-x1;dz=z2-z1;norm=math.hypot(dx,dz);ox=-dz/norm*.006;oz=dx/norm*.006
            panel('Mark',[(x1-ox,.235,z1-oz),(x2-ox,.235,z2-oz),(x2+ox,.235,z2+oz),(x1+ox,.235,z1+oz)],ink,'head')
        group=pieces[begin:];del pieces[begin:]
        bpy.ops.object.select_all(action='DESELECT')
        for obj in group:obj.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
        mark=bpy.context.object;mark.name='MajinMark';extras.append(mark)
    # Separate skinned hair meshes allow live silhouette swaps without reloading a rig.
    for style in ['base','raised','long'] if warrior=='goku' else ['base']:
        begin=len(pieces)
        part('HairCap',(0,-.025,2.68),(.30,.25,.23),hair,'head')
        for i in range(9):
            angle=i*math.tau/9
            upright=warrior=='vegeta' or style!='base'
            x=math.cos(angle)*.22;y=math.sin(angle)*.18
            bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.15,radius2=0,depth=.66 if upright else .55,location=(x,y,2.88))
            obj=bpy.context.object;obj.name='HairSpike'
            obj.rotation_euler=(math.sin(angle)*(.18 if upright else .7),math.cos(angle)*(.2 if upright else .9),0)
            obj.data.materials.append(hair);g=obj.vertex_groups.new(name='head');g.add(list(range(len(obj.data.vertices))),1,'REPLACE');pieces.append(obj)
        if style=='long':
            # Layered tapered locks follow the head bone and extend behind the waist.
            for row in range(4):
                for side in [-1,0,1]:
                    bpy.ops.mesh.primitive_cone_add(vertices=7,radius1=.20-row*.025,radius2=.025,depth=.75,location=(side*(.22-row*.03),-.28-row*.12,2.55-row*.33))
                    obj=bpy.context.object;obj.name='LongLock';obj.rotation_euler=(math.pi+.28,side*.18,0)
                    obj.data.materials.append(hair);g=obj.vertex_groups.new(name='head');g.add(list(range(len(obj.data.vertices))),1,'REPLACE');pieces.append(obj)
        group=pieces[begin:];del pieces[begin:]
        bpy.ops.object.select_all(action='DESELECT')
        for obj in group:obj.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
        obj=bpy.context.object;obj.name='HairStyle_'+style
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        hair_groups[style]=obj
    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces:obj.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();body=bpy.context.object;body.name='WarriorMesh'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.armature_add(location=(0,0,0));rig=bpy.context.object;rig.name='WarriorRig'
    bpy.ops.object.mode_set(mode='EDIT');bones=rig.data.edit_bones;bones.remove(bones[0])
    def bone(name,head,tail,parent=None):
        b=bones.new(name);b.head=head;b.tail=tail
        if parent:b.parent=bones[parent]
    bone('hips',(0,0,1.1),(0,0,1.4));bone('spine',(0,0,1.4),(0,0,2.15),'hips');bone('head',(0,0,2.15),(0,0,2.75),'spine')
    for side in [-1,1]:
        s='L' if side<0 else 'R'
        bone('eye'+s,(side*.11,.25,2.48),(side*.11,.25,2.53),'head')
        bone('arm'+s,(side*.43,0,2.05),(side*.55,0,1.64),'spine');bone('forearm'+s,(side*.55,0,1.64),(side*.56,0,1.1),'arm'+s)
        bone('hand'+s,(side*.56,.025,1.25),(side*.56,.035,1.04),'forearm'+s)
        for finger in range(4):
            x=side*.56+(finger-1.5)*.05
            bone('finger'+str(finger)+s,(x,.06,1.08),(x,.06,.91),'hand'+s)
        bone('thumb'+s,(side*.65,.06,1.19),(side*.7,.06,1.09),'hand'+s)
        bone('thigh'+s,(side*.23,0,1.2),(side*.23,0,.66),'hips');bone('shin'+s,(side*.23,0,.66),(side*.23,.05,.12),'thigh'+s)
        bone('foot'+s,(side*.23,.05,.20),(side*.23,.25,.14),'shin'+s)
    bpy.ops.object.mode_set(mode='OBJECT');
    for mesh in [body,*hair_groups.values(),*extras]:
        mod=mesh.modifiers.new('Skin','ARMATURE');mod.object=rig;mesh.parent=rig
    clips={'idle':90,'walk':36,'run':24,'sprint':18,'flight':36,'hover':48,'ascend':30,'descend':30,'punch':16,'hook':18,'uppercut':20,'medium':20,'kick':24,'grapple':28,'guard':36,'parry':16,'charge':36,'transform':48,'transform_calm':48,'transform_power':48,'beam':40,'final_flash':40,'beam_release':24,'sphere':42,'sphere_release':24,'ki_blast':18,'rush':24,'vanish':12,'dodge':18,'hit':18,'fall':30,'land':18,'victory':48,'defeat':32}
    strikes=['punch','hook','uppercut','medium','kick','grapple']
    for name,length in clips.items():
        rig.animation_data_create();rig.animation_data.action=None
        frames=[(1,0),(length//4,.5),(length//2,1),(length*3//4,.5),(length,0)]
        if name in strikes:
            frames=[(1,0),(max(2,int(length*.18)),-.18),(int(length*.42),1),(int(length*.65),.8),(length,0)]
        if name=='idle':frames=sorted(frames+[(71,.5),(73,.5),(75,.5)])
        for frame,phase in frames:
            for pbone in rig.pose.bones:
                pbone.rotation_mode='XYZ';pbone.rotation_euler=(0,0,0);pbone.location=(0,0,0);pbone.scale=(1,1,1)
            pose=rig.pose.bones
            cycle=(frame-1)/max(1,length-1)*math.tau
            # Relaxed fighting stance, different lead side and hip rotation per warrior.
            lead='R' if warrior=='goku' else 'L';rear='L' if lead=='R' else 'R'
            pose['spine'].rotation_euler.z=.10 if warrior=='goku' else -.15
            pose['arm'+lead].rotation_euler.x=-.45
            pose['forearm'+lead].rotation_euler.x=-1.0
            pose['arm'+rear].rotation_euler.x=-.25
            pose['forearm'+rear].rotation_euler.x=-1.2
            pose['thighL'].rotation_euler.x=-.08;pose['thighR'].rotation_euler.x=.06
            pose['shinL'].rotation_euler.x=.10;pose['shinR'].rotation_euler.x=.08
            open_hands=name in ['beam','final_flash','beam_release','sphere','sphere_release','ki_blast','charge','transform_calm']
            for side in ['L','R']:
                for finger in range(4):pose['finger'+str(finger)+side].rotation_euler.x=0 if open_hands else -1.45
                pose['thumb'+side].rotation_euler.z=(.25 if side=='L' else -.25) if open_hands else 0
            if name=='idle':
                for side in ['L','R']:pose['eye'+side].scale.y=.08 if frame==73 else 1.0
                pose['spine'].rotation_euler.x=.035*math.sin(cycle)
                pose['head'].rotation_euler.z=-pose['spine'].rotation_euler.z*.5
            if name in ['walk','run','sprint']:
                amplitude={'walk':.35,'run':.65,'sprint':.9}[name]
                for side,offset in [('L',0),('R',math.pi)]:
                    stride=math.sin(cycle+offset)
                    pose['thigh'+side].rotation_euler.x=amplitude*stride
                    pose['shin'+side].rotation_euler.x=max(0,-stride)*.95
                    pose['foot'+side].rotation_euler.x=-max(0,stride)*.18
                    pose['arm'+side].rotation_euler.x=-amplitude*stride*.7
                    pose['forearm'+side].rotation_euler.x=-.55
                pose['spine'].rotation_euler.x=.10 if name=='walk' else .22
                pose['hips'].location.y=abs(math.sin(cycle))*.025
            if name in ['guard','parry']:
                for side in ['L','R']:
                    pose['arm'+side].rotation_euler.x=-.9
                    pose['forearm'+side].rotation_euler.x=-1.25
                pose['spine'].rotation_euler.x=.08
                if name=='parry':
                    pose['arm'+lead].rotation_euler.z=.8*phase
                    pose['spine'].rotation_euler.z=.35*phase
            if name in ['charge','transform','transform_power','transform_calm']:
                calm=name=='transform_calm'
                power=1.0 if name=='transform_power' else .6
                for side,sign in [('L',1),('R',-1)]:
                    pose['arm'+side].rotation_euler.x=-.1 if calm else -.3
                    pose['arm'+side].rotation_euler.z=sign*(.12 if calm else .25+power*phase*.2)
                    pose['forearm'+side].rotation_euler.x=-.12 if calm else -.9+phase*.4
                pose['spine'].rotation_euler.x=.025*phase if calm else -.12*phase
                pose['head'].rotation_euler.x=-.08*phase
            if name=='beam':
                for side in ['L','R']:
                    pose['arm'+side].rotation_euler.x=-.7 if warrior=='goku' else -1.0
                    pose['forearm'+side].rotation_euler.x=-1.1
                    pose['arm'+side].rotation_euler.z=.6 if side=='L' else -.2
                    pose['hand'+side].rotation_euler.z=.35 if side=='L' else -.35
                pose['spine'].rotation_euler.z=.5 if warrior=='goku' else -.4
            if name=='final_flash':
                for side,sign in [('L',1),('R',-1)]:
                    pose['arm'+side].rotation_euler.x=-.1
                    pose['arm'+side].rotation_euler.z=sign*1.25
                    pose['forearm'+side].rotation_euler.x=-.15
                pose['spine'].rotation_euler.x=-.1
            if name in ['beam_release','sphere_release']:
                for side in ['L','R']:
                    pose['arm'+side].rotation_euler.x=-1.65
                    pose['arm'+side].rotation_euler.z=.25 if side=='L' else -.25
                    pose['forearm'+side].rotation_euler.x=0
                pose['spine'].rotation_euler.x=.18
            if name=='sphere':
                for side in ['L','R']:
                    pose['arm'+side].rotation_euler.x=-3.1 if warrior=='goku' else (-1.6 if side=='R' else -.3)
                    pose['forearm'+side].rotation_euler.x=0
                    if warrior=='goku':pose['arm'+side].rotation_euler.z=.28 if side=='L' else -.28
            if name in strikes:
                pose['spine'].rotation_euler.z=(.35 if warrior=='goku' else -.35)*phase
                if name in ['punch','hook','uppercut','grapple']:
                    arm=lead if name in ['punch','uppercut'] else rear
                    pose['arm'+arm].rotation_euler.x=-.45-1.25*phase
                    pose['forearm'+arm].rotation_euler.x=-1.0+phase*.98
                    if name=='hook':
                        pose['arm'+arm].rotation_euler.z=.75*phase
                        pose['forearm'+arm].rotation_euler.x=-.8
                    if name=='uppercut':pose['arm'+arm].rotation_euler.x=-.45-1.95*phase;pose['forearm'+arm].rotation_euler.x=-.55
                    if name=='grapple':pose['arm'+rear].rotation_euler.x=-1.5*phase
                else:
                    leg='L' if name=='medium' else 'R'
                    pose['thigh'+leg].rotation_euler.x=-1.6*phase
                    pose['shin'+leg].rotation_euler.x=.7*(1-phase) if phase>0 else .2
                    pose['foot'+leg].rotation_euler.x=-.25*phase
                    pose['spine'].rotation_euler.x=-.15*phase
            if name in ['flight','hover','ascend','descend','rush']:
                pose['spine'].rotation_euler.x=.45 if name in ['flight','rush'] else .12
                pose['thighL'].rotation_euler.x=.15;pose['thighR'].rotation_euler.x=-.12
                pose['shinL'].rotation_euler.x=.35;pose['shinR'].rotation_euler.x=.22
                if name=='ascend':pose['arm'+lead].rotation_euler.x=-2.7
                if name=='descend':pose['thighR'].rotation_euler.x=.4
                if name=='rush':pose['arm'+lead].rotation_euler.x=-1.7;pose['forearm'+lead].rotation_euler.x=0
            if name=='ki_blast':pose['arm'+lead].rotation_euler.x=-1.6;pose['forearm'+lead].rotation_euler.x=-.1
            if name=='vanish':pose['armR'].rotation_euler.x=-2.1*phase;pose['forearmR'].rotation_euler.x=-1.25
            if name=='dodge':pose['spine'].rotation_euler.z=-.45*phase;pose['head'].rotation_euler.z=.2*phase
            if name=='hit':pose['spine'].rotation_euler.x=-.35*phase;pose['head'].rotation_euler.x=-.2*phase
            if name=='fall':pose['spine'].rotation_euler.x=-.6;pose['thighL'].rotation_euler.x=.3;pose['armR'].rotation_euler.z=-.8
            if name=='land':
                pose['thighL'].rotation_euler.x=-.5*phase;pose['thighR'].rotation_euler.x=-.5*phase
                pose['shinL'].rotation_euler.x=.9*phase;pose['shinR'].rotation_euler.x=.9*phase
                pose['spine'].rotation_euler.x=.25*phase
                pose['hips'].location.y=-.12*phase
            if name=='victory':
                if warrior=='goku':pose['armR'].rotation_euler.x=-2.7*phase;pose['forearmR'].rotation_euler.x=-.2
                else:
                    pose['armL'].rotation_euler.x=-.9;pose['armR'].rotation_euler.x=-.9
                    pose['forearmL'].rotation_euler.x=-1.4;pose['forearmR'].rotation_euler.x=-1.4
                    pose['armL'].rotation_euler.z=.5;pose['armR'].rotation_euler.z=-.5
            if name=='defeat':pose['hips'].rotation_euler.x=1.4*(frame/length)
            # Authored angles use the gameplay convention; Blender faces +Y.
            for pbone in pose:
                pbone.rotation_euler.x *= -1
                pbone.keyframe_insert(data_path='rotation_euler',frame=frame)
                pbone.keyframe_insert(data_path='location',frame=frame)
                pbone.keyframe_insert(data_path='scale',frame=frame)
        rig.animation_data.action.name=name
    bpy.context.scene.render.fps=30
    bpy.ops.export_scene.gltf(filepath=str(OUT/(warrior+'.glb')),export_format='GLB',export_animation_mode='ACTIONS',export_anim_single_armature=True)
print('Exported original skinned characters, 34 clips per rig and switchable hair meshes, and sculpted rock.')
