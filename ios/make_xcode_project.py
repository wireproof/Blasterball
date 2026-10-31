from pathlib import Path
import plistlib
root=Path(__file__).resolve().parent
objects={};seq=0
def add(isa,**kw):
 global seq
 seq+=1;k=f'{seq:024X}';objects[k]={'isa':isa,**kw};return k
source=add('PBXFileReference',lastKnownFileType='sourcecode.swift',path='Game.swift',sourceTree='<group>')
third=add('PBXFileReference',lastKnownFileType='folder',path='Resources/BB3',sourceTree='<group>')
audioSource=add('PBXFileReference',lastKnownFileType='sourcecode.swift',path='Audio.swift',sourceTree='<group>')
extras=[add('PBXFileReference',lastKnownFileType='sourcecode.swift',path=p.name,sourceTree='<group>') for p in sorted(root.glob('*.swift')) if p.name not in ['Game.swift','Audio.swift']]
campaign=add('PBXFileReference',lastKnownFileType='text.json',path='Resources/campaign.json',sourceTree='<group>')
backdrop=add('PBXFileReference',lastKnownFileType='folder',path='Resources/Editions',sourceTree='<group>')
campaigns=add('PBXFileReference',lastKnownFileType='folder',path='Resources/Campaigns',sourceTree='<group>')
audio=add('PBXFileReference',lastKnownFileType='folder',path='Resources/Audio',sourceTree='<group>')
menu=add('PBXFileReference',lastKnownFileType='folder',path='Resources/Menu',sourceTree='<group>')
assets=add('PBXFileReference',lastKnownFileType='folder.assetcatalog',path='Assets.xcassets',sourceTree='<group>')
info=add('PBXFileReference',lastKnownFileType='text.plist.xml',path='Info.plist',sourceTree='<group>')
product=add('PBXFileReference',explicitFileType='wrapper.application',includeInIndex=0,path='Blasterball.app',sourceTree='BUILT_PRODUCTS_DIR')
prodgroup=add('PBXGroup',children=[product],name='Products',sourceTree='<group>')
group=add('PBXGroup',children=extras+[source,audioSource,third,campaign,campaigns,backdrop,audio,menu,assets,info,prodgroup],sourceTree='<group>')
sources=add('PBXSourcesBuildPhase',buildActionMask=2147483647,files=[add('PBXBuildFile',fileRef=x) for x in [source,audioSource]+extras],runOnlyForDeploymentPostprocessing=0)
resources=add('PBXResourcesBuildPhase',buildActionMask=2147483647,files=[add('PBXBuildFile',fileRef=x) for x in [campaign,campaigns,backdrop,audio,menu,third,assets]],runOnlyForDeploymentPostprocessing=0)
frameworks=add('PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)
def configs(target=False):
 out=[]
 for name in ['Debug','Release']:
  settings={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'16.0','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O'}
  if target:settings.update({'PRODUCT_NAME':'Blasterball','PRODUCT_BUNDLE_IDENTIFIER':'com.wireproof.blasterball.prototype','DEVELOPMENT_TEAM':'KTV9W3H439','CODE_SIGN_STYLE':'Automatic','INFOPLIST_FILE':'Info.plist','GENERATE_INFOPLIST_FILE':'NO','TARGETED_DEVICE_FAMILY':'1,2','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks'],'ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
  out.append(add('XCBuildConfiguration',name=name,buildSettings=settings))
 return add('XCConfigurationList',buildConfigurations=out,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
target=add('PBXNativeTarget',buildConfigurationList=configs(True),buildPhases=[sources,frameworks,resources],buildRules=[],dependencies=[],name='Blasterball',productName='Blasterball',productReference=product,productType='com.apple.product-type.application')
project=add('PBXProject',attributes={'LastUpgradeCheck':'2710','TargetAttributes':{target:{'CreatedOnToolsVersion':'27.1','DevelopmentTeam':'KTV9W3H439','ProvisioningStyle':'Automatic'}}},buildConfigurationList=configs(),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=group,productRefGroup=prodgroup,projectDirPath='',projectRoot='',targets=[target])
p=root/'Blasterball.xcodeproj';p.mkdir(exist_ok=True);(p/'project.pbxproj').write_bytes(plistlib.dumps({'archiveVersion':'1','classes':{},'objectVersion':'56','objects':objects,'rootObject':project},sort_keys=False))
