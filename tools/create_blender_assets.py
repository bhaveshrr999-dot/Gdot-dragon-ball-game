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
    reset(); pieces=[]
    skin=material('Skin',(.68,.38,.22)); cloth=material('Costume',(.92,.22,.035) if warrior=='goku' else (.025,.12,.42))
    navy=material('BlueTrim',(.015,.04,.16));white=material('Armor',(.85,.85,.78));hair=material('Hair',(.015,.012,.025));black=material('Eyes',(.008,.01,.02));gold=material('ArmorGold',(.65,.46,.13))
    def part(name, pos, scale, mat, bone):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=pos)
        obj=bpy.context.object;obj.name=name;obj.scale=scale
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        obj.data.materials.append(mat)
        for f in obj.data.polygons:f.use_smooth=True
        group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        pieces.append(obj);return obj
    part('Torso',(0,0,1.72),(.43,.24,.50),cloth,'spine')
    part('Belt',(0,0,1.29),(.41,.255,.09),navy if warrior=='goku' else gold,'hips')
    part('Neck',(0,0,2.19),(.13,.13,.16),skin,'head')
    part('Head',(0,0,2.45),(.29,.255,.34),skin,'head')
    part('Jaw',(0,.09,2.29),(.21,.20,.17),skin,'head')
    part('Nose',(0,.27,2.41),(.045,.07,.07),skin,'head')
    for side in [-1,1]:
        suffix='L' if side<0 else 'R'
        part('Eye'+suffix,(side*.11,.238,2.48),(.082,.035,.047),white,'head')
        part('Pupil'+suffix,(side*.11,.272,2.48),(.025,.014,.035),black,'head')
        part('Brow'+suffix,(side*.11,.26,2.54),(.10,.025,.018),hair,'head')
        part('UpperArm'+suffix,(side*.53,0,1.86),(.17,.18,.30),skin if warrior=='goku' else cloth,'arm'+suffix)
        part('Forearm'+suffix,(side*.56,.025,1.43),(.13,.15,.25),skin if warrior=='goku' else cloth,'forearm'+suffix)
        part('Wrist'+suffix,(side*.56,.025,1.26),(.14,.16,.085),navy if warrior=='goku' else white,'forearm'+suffix)
        part('Hand'+suffix,(side*.56,.035,1.13),(.13,.14,.15),skin if warrior=='goku' else white,'forearm'+suffix)
        part('Thigh'+suffix,(side*.23,0,.94),(.21,.22,.39),cloth,'thigh'+suffix)
        part('Shin'+suffix,(side*.23,0,.42),(.15,.17,.30),cloth,'shin'+suffix)
        part('Boot'+suffix,(side*.23,.075,.18),(.17,.26,.18),navy if warrior=='goku' else white,'shin'+suffix)
    if warrior=='vegeta':
        part('ChestArmor',(0,.17,1.79),(.39,.12,.34),white,'spine')
        part('ArmorPanel',(0,.26,1.57),(.29,.04,.12),gold,'spine')
    else:
        part('Undershirt',(0,.205,2.02),(.19,.055,.18),navy,'spine')
    part('HairCap',(0,-.025,2.68),(.30,.25,.23),hair,'head')
    for i in range(9):
        angle=i*math.tau/9
        x=math.cos(angle)*.22;y=math.sin(angle)*.18
        bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=.15,radius2=0,depth=.62 if warrior=='vegeta' else .55,location=(x,y,2.88))
        obj=bpy.context.object;obj.name='HairSpike';obj.rotation_euler=(math.sin(angle)*(.18 if warrior=='vegeta' else .7),math.cos(angle)*(.2 if warrior=='vegeta' else .9),0)
        obj.data.materials.append(hair);g=obj.vertex_groups.new(name='head');g.add(list(range(len(obj.data.vertices))),1,'REPLACE');pieces.append(obj)
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
        bone('arm'+s,(side*.43,0,2.05),(side*.55,0,1.64),'spine');bone('forearm'+s,(side*.55,0,1.64),(side*.56,0,1.1),'arm'+s)
        bone('thigh'+s,(side*.23,0,1.2),(side*.23,0,.66),'hips');bone('shin'+s,(side*.23,0,.66),(side*.23,.05,.12),'thigh'+s)
    bpy.ops.object.mode_set(mode='OBJECT');mod=body.modifiers.new('Skin','ARMATURE');mod.object=rig;body.parent=rig
    clips={'idle':40,'run':24,'flight':30,'punch':16,'kick':24,'guard':24,'charge':36,'transform':48,'beam':40,'hit':18,'victory':48,'defeat':32}
    for name,length in clips.items():
        rig.animation_data_create();rig.animation_data.action=None
        for frame,phase in [(1,0),(length//2,1),(length,0)]:
            for p in rig.pose.bones:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0)
            pose=rig.pose.bones
            if name=='idle':pose['spine'].rotation_euler.x=.025*phase
            if name=='run':
                pose['thighL'].rotation_euler.x=.7*(1 if phase else -1);pose['thighR'].rotation_euler.x=-pose['thighL'].rotation_euler.x
                pose['armL'].rotation_euler.x=-pose['thighL'].rotation_euler.x;pose['armR'].rotation_euler.x=-pose['thighR'].rotation_euler.x
            if name in ['guard','charge','beam','transform']:
                for s in ['L','R']:
                    pose['arm'+s].rotation_euler.x=-(1.3 if name!='transform' else .5)*phase
                    pose['forearm'+s].rotation_euler.x=-.55*phase
            if name=='punch':pose['armR' if warrior=='goku' else 'armL'].rotation_euler.x=-1.7*phase;pose['spine'].rotation_euler.z=.25*phase
            if name=='kick':pose['thighR'].rotation_euler.x=-1.6*phase;pose['spine'].rotation_euler.x=.2*phase
            if name=='flight':pose['spine'].rotation_euler.x=.25
            if name=='hit':pose['spine'].rotation_euler.x=-.3*phase
            if name=='victory':pose['armR'].rotation_euler.x=-2.7*phase
            if name=='defeat':pose['hips'].rotation_euler.x=1.4*(frame/length)
            for p in pose:p.keyframe_insert(data_path='rotation_euler',frame=frame)
        rig.animation_data.action.name=name
    bpy.context.scene.render.fps=30
    bpy.ops.export_scene.gltf(filepath=str(OUT/(warrior+'.glb')),export_format='GLB',export_animation_mode='ACTIONS',export_anim_single_armature=True)
print('Exported original skinned characters, twelve clips per rig, and sculpted rock.')
