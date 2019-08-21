# container
deploy container script
# 用 pull.sh下载镜像并导出 依赖images文件
# 用 load.sh 导入镜像 依赖上一步生成的*.tar 和tag
# 把  dock.sh load.sh images tag *.tar 发送给要部署的服务器
# 用 dock.sh 初始化master 依赖主机名<master> 生成kubejoin文件发送给node
# 用 dock.sh 部署kubeadm到node，并使用上一步生成的kubejoin文件获取参数加入集群
