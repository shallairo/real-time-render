实时阴影效果对比
![origin](shadowMapping.png)
![pcf](pcf.png)
![pcss](pcss.png)
ssao，ssdo效果对比
![origin](origin.png)
![ssao](SSAO.png)
![ssao&&ssdo](AODO.png)
micofacet BRDF pbr理解思路
尤其注意其中关于能量补偿部分，理应是去做一求一个近似的fenier和brdf乘积，实际较为复杂，还需打表和额外存储，故工业界一般采取加上一个diffuse材质的brdf近似补偿。不理解但是速度才是王道！！！！

![understanding](PBR.jpg)
实现效果
![pbr](micoficetBRDF.png)

