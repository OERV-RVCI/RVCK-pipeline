# TODO

- 流水线流程变化，调用关系和顺序
- check-patch 检查结果, error, warning数统计后怎么处理。是否继续执行检查
- github tag是否新增
- kernel-build, kunit-test, 可以并行跑, 或者kunit-test 复用当前kernel-build环境, 减少代码拉取次数
- rootfs_download_url, 可配置
- push， 发邮件


这个错误：
```
hudson.remoting.ProxyException: java.nio.charset.MalformedInputException: Input length = 1
```
表明 **Jenkins 代理 (Agent) 远程调用 `load` 方法时，读取 Groovy 文件内容失败**，通常是由于 **文件编码、路径、文件权限或传输问题** 造成的。

---

### **📌 可能的原因及解决方案**
#### **1️⃣ Groovy 文件编码问题**
Jenkins 期望 **UTF-8 编码**，如果 `utils/tools.groovy` 是 **GBK** 或 **其他编码**，可能导致 `MalformedInputException`。

✅ **解决方案：检查编码**
在 Jenkins Agent 服务器上执行：
```sh
file -i utils/tools.groovy
```
如果不是 `utf-8`，转换为 UTF-8：
```sh
iconv -f GBK -t UTF-8 utils/tools.groovy -o tools_utf8.groovy
```

然后更新 `Jenkinsfile`，指向新的 UTF-8 文件：
```groovy
def tools = load 'utils/tools_utf8.groovy'
```

---

#### **2️⃣ `load` 的 Groovy 文件路径问题**
Jenkins 可能在 **错误的路径** 下尝试 `load` 脚本。

✅ **解决方案：检查路径**
在 **Jenkins Pipeline** 中先检查文件是否存在：
```groovy
if (fileExists('utils/tools.groovy')) {
    def tools = load 'utils/tools.groovy'
    echo "Script loaded successfully!"
} else {
    error "Error: utils/tools.groovy not found!"
}
```
如果报错，尝试使用 **绝对路径**：
```groovy
def tools = load "${WORKSPACE}/utils/tools.groovy"
```

---

#### **3️⃣ 文件权限不足**
Jenkins **可能没有权限** 读取 `tools.groovy`，导致 `load` 失败。

✅ **解决方案：修改权限**
在 Jenkins Agent 服务器上：
```sh
chmod 644 utils/tools.groovy
chown jenkins:jenkins utils/tools.groovy
```
然后 **重新触发 Jenkins 构建**。

---

#### **4️⃣ 代理 (Agent) 远程调用异常**
如果 Jenkins **Master 与 Agent 之间的网络连接不稳定**，也可能导致 `MalformedInputException`。

✅ **解决方案：重新启动 Agent**
在 **Jenkins Web UI** 中：
1. **断开并重启 Agent**
2. **重新执行 Pipeline**

如果 Agent 运行在 Docker 里，可以手动重启：
```sh
docker restart jenkins-agent
```

---

#### **5️⃣ Jenkins Master 和 Agent 语言环境不匹配**
如果 **Jenkins Master 和 Agent 的 `locale` 不匹配**，可能导致 `load` 解析文件失败。

✅ **解决方案：统一 `locale`**
在 **Jenkins Master 和 Agent** 终端执行：
```sh
locale
```
如果 `LANG` 不是 `en_US.UTF-8`，修改为：
```sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```
或者在 `Jenkinsfile` 里：
```groovy
sh 'export LANG=en_US.UTF-8'
```

---

### **🎯 总结**
✅ **按顺序排查问题**
1. **检查 Groovy 文件是否是 UTF-8** (`file -i utils/tools.groovy`)
2. **确认 `tools.groovy` 是文本文件** (`file utils/tools.groovy`)
3. **检查 `load` 的路径是否正确** (`fileExists('utils/tools.groovy')`)
4. **赋予 Jenkins 读权限** (`chmod 644 utils/tools.groovy`)
5. **确保 Jenkins Master 和 Agent `locale` 统一** (`LANG=en_US.UTF-8`)
6. **尝试重启 Jenkins Agent** (`docker restart jenkins-agent`)

试试看这些方法，应该可以解决 `load` 时报错的问题！🚀