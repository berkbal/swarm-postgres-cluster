# Swarm Postgres Cluster

Bu proje Docker Swarm kullanarak PostgreSQL master-slave replikasyon cluster'ı oluşturmak için tasarlanmıştır. Proje, yüksek erişilebilirlik sağlamak amacıyla master sunucu üzerinde yazma işlemlerini, slave sunucu üzerinde ise okuma işlemlerini gerçekleştirecek şekilde yapılandırılmıştır.

## Proje Yapısı

```
.
├── stack.yml              # Docker Swarm stack yapılandırması
├── master-init/           # Master sunucu başlangıç dosyaları
│   ├── init-replication.sql    # Replikasyon kullanıcısı ve slot oluşturma
│   ├── pg_hba.conf            # PostgreSQL erişim kontrol dosyası
│   └── setup-hba.sh           # HBA konfigürasyonu uygulama scripti
└── slave-init/            # Slave sunucu başlangıç dosyaları
    └── setup-slave.sh         # Slave replikasyon kurulum scripti
```

## Başlangıçta

### Master Sunucu
- Replikasyon için gerekli parametrelerle başlatılır
- `replication` kullanıcısı ve `db2` replikasyon slotu oluşturur
- Tüm IP adreslerinden bağlantı kabul eder(Duruma göre **sıkılaştırma kesinlikle önerilir!!!**)

### Slave Sunucu
- Master sunucunun hazır olmasını bekler
- `pg_basebackup` ile master'dan tam backup alır
- `db2` replikasyon slot'unu kullanarak streaming replikasyon başlatır
- Read-only modunda çalışır

### 2377, 7946 ve 4789 portlarının sunucular arası erişime açık olması gerekmektedir!

## Docker Swarm Kurulum Adımları

### 1. Docker Swarm Cluster'ı Oluşturma

#### Manager Node (Master Sunucu)
```bash
# Swarm'ı başlat
sudo docker swarm init --advertise-addr <MANAGER-IP>

# Worker node'lar için join token'ı göster
sudo docker swarm join-token worker
```

#### Worker Node (Slave Sunucu)
```bash
# Manager'dan alınan token ile worker node'u join et
sudo docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

### 2. Node Etiketlerini Ayarlama

PostgreSQL servislerinin doğru sunucularda çalışması için node etiketlerini ayarlayın:

```bash
# Manager node'da master etiketini ayarla
sudo docker node update --label-add purpose=master <MANAGER-NODE-ID>

# Worker node'da worker etiketini ayarla
sudo docker node update --label-add purpose=worker <WORKER-NODE-ID>
```

Node ID'lerini görmek için:
```bash
sudo docker node ls
```

### 3. Stack'i Deploy Etme

```bash
# Proje dizinine git
cd /repoyu/clonladıgınız-dizin/Postgresql-Replication-Cluster-with-Docker-Swarm

# Stack'i deploy et
sudo docker stack deploy -c stack.yml postgres-cluster
```

### 4. Durumu Kontrol Etme

```bash
# Servislerin durumunu kontrol et
sudo docker stack services postgres-cluster

# Container loglarını görüntüle
sudo docker service logs postgres-cluster_postgres-master
sudo docker service logs postgres-cluster_postgres-slave
```

## Bağlantı Bilgileri (Mutlaka Değiştirilmeli!)

### Master Sunucu (Yazma İşlemleri)
- **Host:** Manager Node IP
- **Port:** 5432
- **Database:** postgres
- **Username:** postgres
- **Password:** 123

### Slave Sunucu (Okuma İşlemleri)
- **Host:** Worker Node IP
- **Port:** 5432
- **Database:** postgres
- **Username:** postgres
- **Password:** 123
  

## Önemli Notlar

1. **Veri Kalıcılığı:** Veriler Docker volume'lar ile korunur. Volume'lar silinirse veriler kaybolur.
   
2. **Monitoring:** Replikasyon durumunu izlemek için aşağıdaki sorguları kullanabilirsiniz:
   ```sql
   -- Master'da
   SELECT * FROM pg_replication_slots;
   SELECT * FROM pg_stat_replication;
   
   -- Slave'de
   SELECT * FROM pg_stat_wal_receiver;
   ```
