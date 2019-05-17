#!/usr/bin/env python
#coding:utf-8
import os
import json
import hashlib
import subprocess


assetsDir = {
    "searchDir" : ["src", "res/lobby"],
    "ignoreDir" : ["cocos", "obj", "patch", "jdnn", "zjh", "qznn", "lhd"]
}


versionConfigFile = "res/patch/lobby_version_info.json"   #版本信息的配置文件路径
versionManifestPath = "res/patch/lobby/version.manifest"  #由此脚本生成的version.manifest文件路径
projectManifestPath = "res/patch/lobby/project.manifest"  #由此脚本生成的project.manifest文件路径


class SearchFile:
    def __init__(self):
        self.fileList = []

        for k in assetsDir:
            if (k == "searchDir"):
                for searchdire in assetsDir[k]:                 
                    self.recursiveDir(searchdire)

    def recursiveDir(self, srcPath):
        ''' 递归指定目录下的所有文件'''
        dirList = []    #所有文件夹  

        files = os.listdir(srcPath) #返回指定目录下的所有文件，及目录（不含子目录）

        for f in files:         
            #目录的处理
            if (os.path.isdir(srcPath + '/' + f)):              
                if (f[0] == '.' or (f in assetsDir["ignoreDir"])):
                    #排除隐藏文件夹和忽略的目录
                    pass
                else:
                    #添加非需要的文件夹                                  
                    dirList.append(f)

            #文件的处理
            elif (os.path.isfile(srcPath + '/' + f)):               
                self.fileList.append(srcPath + '/' + f) #添加文件

        #遍历所有子目录,并递归
        for dire in dirList:        
            #递归目录下的文件
            self.recursiveDir(srcPath + '/' + dire)

    def getAllFile(self):
        ''' get all file path'''
        return tuple(self.fileList)


def getSvnCurrentVersion(): 
    popen = subprocess.Popen(['svn', 'info'], stdout = subprocess.PIPE)    
    while True:
        next_line = popen.stdout.readline()         
        if next_line == '' and popen.poll() != None:
            break

        valList = next_line.split(':')      
        if len(valList)<2:
            continue
        valList[0] = valList[0].strip().lstrip().rstrip(' ')
        valList[1] = valList[1].strip().lstrip().rstrip(' ')

        if(valList[0]=="Revision"):
            return valList[1]
    return ""


def calcMD5(filepath):
    """generate a md5 code by a file path"""
    with open(filepath,'rb') as f:
        md5obj = hashlib.md5()
        md5obj.update(f.read())
        return md5obj.hexdigest()


def getVersionInfo():
    '''get version config data'''
    configFile = open(versionConfigFile,"r")
    json_data = json.load(configFile)
    configFile.close()
    #json_data["version"] = json_data["version"] + '.' + str(getSvnCurrentVersion())
    return json_data


def genVersionManifestPath():
    ''' 生成大版本的version.manifest'''
    json_str = json.dumps(getVersionInfo(), indent = 2)
    fo = open(versionManifestPath,"w")  
    fo.write(json_str)  
    fo.close()


def genProjectManifestPath():
    searchfile = SearchFile()
    fileList = list(searchfile.getAllFile())
    project_str = {}
    project_str.update(getVersionInfo())
    dataDic = {}
    for f in fileList:      
        dataDic[f] = {"md5" : calcMD5(f)}

    project_str.update({"assets":dataDic})
    json_str = json.dumps(project_str, sort_keys = True, indent = 2)

    fo = open(projectManifestPath,"w")  
    fo.write(json_str)  
    fo.close()


if __name__ == "__main__":
    genVersionManifestPath()
    genProjectManifestPath()