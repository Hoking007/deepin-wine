REPO ?= repo
BUILD ?= build

.PHONY: all download generate clean

all: download
	$(MAKE) generate

generate: $(REPO)/Release $(REPO)/setup.sh

clean:
	rm -rf $(BUILD) $(REPO)

download:
	mkdir -p $(BUILD)
	@python3 download.py -v -d '$(BUILD)' \
		-t 'https://mirrors.tuna.tsinghua.edu.cn/{0}/dists/{1}/{2}/binary-{3}/Packages{4}' -s '~' \
		-f deepin~stable~main~i386~.gz \
		-f deepin~stable~main~amd64~.gz \
		-f deepin~stable~non-free~i386~.gz \
		-f debian~stable~main~i386~.xz \
		-f debian~testing~main~i386~.xz \
		-f ubuntu~bionic~main~i386~.xz \
		-f ubuntu~bionic~universe~i386~.xz \
		-f ubuntu~focal~main~i386~.xz \
		-f ubuntu~focal~universe~i386~.xz

$(BUILD)/%~: $(BUILD)/%~.gz
	gzip -cd $< >$@

$(BUILD)/%~: $(BUILD)/%~.xz
	xz -cd $< >$@

$(BUILD)/deepin.pkg: $(BUILD)/deepin~stable~main~i386~ $(BUILD)/deepin~stable~non-free~i386~ $(BUILD)/deepin~stable~main~amd64~
$(BUILD)/debian-stable.pkg: $(BUILD)/debian~stable~main~i386~
$(BUILD)/debian-testing.pkg: $(BUILD)/debian~testing~main~i386~
$(BUILD)/ubuntu-bionic.pkg: $(BUILD)/ubuntu~bionic~main~i386~ $(BUILD)/ubuntu~bionic~universe~i386~
$(BUILD)/ubuntu-focal.pkg: $(BUILD)/ubuntu~focal~main~i386~ $(BUILD)/ubuntu~focal~universe~i386~

$(BUILD)/%.pkg:
	for f in $+; do sed -E -e '/^#/d' -e '$$ s/$$/\n\n/' $$f; done >$@

$(BUILD)/%.trans: $(BUILD)/deepin.pkg $(BUILD)/%.pkg
	@python3 transplant.py -o $@ transplant -s $< -t $(lastword $+) \
		deepin.cn.360.yasuo \
		deepin.cn.com.winrar \
		deepin.com.95579.cjsc \
		deepin.com.aaa-logo \
		deepin.com.baidu.pan \
		deepin.com.cmbchina \
		deepin.com.foxmail \
		deepin.com.gtja.fuyi \
		deepin.com.qq.b.crm \
		deepin.com.qq.b.eim \
		deepin.com.qq.im \
		deepin.com.qq.im.light \
		deepin.com.qq.office \
		deepin.com.qq.rtx2015 \
		deepin.com.taobao.aliclient.qianniu \
		deepin.com.taobao.wangwang \
		deepin.com.thunderspeed \
		deepin.com.wechat \
		deepin.com.weixin.work \
		deepin.net.263.em \
		deepin.org.7-zip \
		deepin.org.foobar2000

$(REPO)/Packages: $(BUILD)/debian-stable.trans $(BUILD)/debian-testing.trans $(BUILD)/ubuntu-bionic.trans $(BUILD)/ubuntu-focal.trans
	mkdir -p $(REPO)/ $(REPO)/deepin_mirror
	python3 transplant.py -o $@ merge $+
	grep -iP '^(Package|Version|Architecture)\s*:|^$$' $@ | sed -e 's/.*\s*:\s*//' | paste -s -d'\t' | sed -E 's/\t\t/\n/g'

$(REPO)/Packages.gz: $(REPO)/Packages
	gzip -c9 $< >$@

$(REPO)/Release: $(REPO)/Packages $(REPO)/Packages.gz
	apt-ftparchive release -o APT::FTPArchive::Release::Label=deepin-wine $(REPO) >$@

$(REPO)/setup.sh: setup.sh
	cp $< $@
