---
layout: about
title: about
permalink: /
subtitle: 上海科技大学 CS 2025 级 · 空间智能 · 具身世界模型

profile:
  align: right
  image: prof_pic.png
  image_circular: false # crops the image to make it circular
  more_info: >
    <p>上海科技大学 计算机科学与技术 2025 级</p>
    <p>zhujl2025@shanghaitech.edu.cn</p>
    <p>GitHub：<a href="https://github.com/CHplus0">CHplus0</a></p>
    <p>ORCID：<a href="https://orcid.org/0009-0004-0138-7670">0009-0004-0138-7670</a></p>
    <p>OpenReview：<a href="https://openreview.net/profile?id=~Jialin_Zhu8">个人主页</a></p>

news: true # includes a list of news items
selected_papers: false # 有可公开展示的成果后再启用
social: true # includes social icons at the bottom of the page
---

我是朱佳林，上海科技大学计算机科学与技术专业 2025 级本科生，大二在读。目前在南京大学安亮老师课题组负责一个动物姿态数据集的标注质量评估与修复，并开展一项姿态估计方向的独立课题（LoopedPose）。

## 研究兴趣

**空间智能与具身世界模型**。关注智能体如何从视觉观测中构建、维护和利用物理世界的内部表征，尤其对空间表征、时序建模与基于内部状态的预测和推理感兴趣。

## 科研经历

**动物姿态数据集：标注质量评估与系统性修复 · 南京大学安亮老师课题组（2026.8 – 2026.9）**

负责数据集的全量标注质量核查与修复，覆盖近 **2 万个动物实例**。借助 Agent 开发审核工具，逐例核查关键点、边界框、分割掩码与物种归属；按标注依赖顺序先修正关键点与边界框，再重新生成分割掩码；终审中定位 **1,332 个标注已更新但掩码未同步的实例**，完成补重跑、人工复判与写回；最后以分层盲审与图级 Bootstrap 置信区间验收修复结果。

**LoopedPose：循环 Transformer 的二维姿态估计与计算效率研究（独立课题，2026.9 – 至今）**

检验循环 Transformer 的权重共享与迭代精化能否改善二维姿态估计的精度–效率权衡。本人负责研究问题定义与研究任务书，规定官方数据划分、评测协议、实验对照与负结果保留要求；基线复现与实验由科研 Agent（DeepScientist）执行，本人设定 GPU 资源上限与运行约束。已完成 HRNet、动物 / 人体 ViTPose、RTMPose 四组基线复现，评测结果经独立复算核验（与官方评分最大差值为 0）；首轮循环方案执行中，结果待本人审阅。

## 开源与技术探索

课余学习机器学习与 Transformer 架构，探索 Agent 辅助开发与学习的工作方式。已开源两个 DeepSeek Harness 插件：[dsh-learning-mode](https://github.com/CHplus0/dsh-learning-mode) 与 [dsh-shell-command](https://github.com/CHplus0/dsh-shell-command)。

## 教育经历

上海科技大学 · 计算机科学与技术 · 本科在读（2025.9 – 至今）
