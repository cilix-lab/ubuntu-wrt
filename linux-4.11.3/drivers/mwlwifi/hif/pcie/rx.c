/*
 * Copyright (C) 2006-2017, Marvell International Ltd.
 *
 * This software file (the "File") is distributed by Marvell International
 * Ltd. under the terms of the GNU General Public License Version 2, June 1991
 * (the "License").  You may use, redistribute and/or modify this File in
 * accordance with the terms and conditions of the License, a copy of which
 * is available by writing to the Free Software Foundation, Inc.
 *
 * THE FILE IS DISTRIBUTED AS-IS, WITHOUT WARRANTY OF ANY KIND, AND THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE
 * ARE EXPRESSLY DISCLAIMED.  The License provides additional details about
 * this warranty disclaimer.
 */

/* Description:  This file implements receive related functions. */

#include <linux/etherdevice.h>
#include <linux/skbuff.h>

#include "sysadpt.h"
#include "core.h"
#include "utils.h"
#include "hif/pcie/dev.h"
#include "hif/pcie/rx.h"

#define MAX_NUM_RX_RING_BYTES  (PCIE_MAX_NUM_RX_DESC * \
				sizeof(struct pcie_rx_desc))

#define MAX_NUM_RX_HNDL_BYTES  (PCIE_MAX_NUM_RX_DESC * \
				sizeof(struct pcie_rx_hndl))

#define DECRYPT_ERR_MASK        0x80
#define GENERAL_DECRYPT_ERR     0xFF
#define TKIP_DECRYPT_MIC_ERR    0x02
#define WEP_DECRYPT_ICV_ERR     0x04
#define TKIP_DECRYPT_ICV_ERR    0x08

#define W836X_RSSI_OFFSET       8

/* Receive rate information constants */
#define RX_RATE_INFO_FORMAT_11A       0
#define RX_RATE_INFO_FORMAT_11B       1
#define RX_RATE_INFO_FORMAT_11N       2
#define RX_RATE_INFO_FORMAT_11AC      4

#define RX_RATE_INFO_HT20             0
#define RX_RATE_INFO_HT40             1
#define RX_RATE_INFO_HT80             2
#define RX_RATE_INFO_HT160            3

#define RX_RATE_INFO_LONG_INTERVAL    0
#define RX_RATE_INFO_SHORT_INTERVAL   1

static int pcie_rx_ring_alloc(struct mwl_priv *priv)
{
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;

	desc = &pcie_priv->desc_data[0];

	desc->prx_ring = (struct pcie_rx_desc *)
		dma_alloc_coherent(priv->dev,
				   MAX_NUM_RX_RING_BYTES,
				   &desc->pphys_rx_ring,
				   GFP_KERNEL);

	if (!desc->prx_ring) {
		wiphy_err(priv->hw->wiphy, "cannot alloc mem\n");
		return -ENOMEM;
	}

	memset(desc->prx_ring, 0x00, MAX_NUM_RX_RING_BYTES);

	desc->rx_hndl = kzalloc(MAX_NUM_RX_HNDL_BYTES, GFP_KERNEL);

	if (!desc->rx_hndl) {
		dma_free_coherent(priv->dev,
				  MAX_NUM_RX_RING_BYTES,
				  desc->prx_ring,
				  desc->pphys_rx_ring);
		return -ENOMEM;
	}

	return 0;
}

static int pcie_rx_ring_init(struct mwl_priv *priv)
{
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;
	int i;
	struct pcie_rx_hndl *rx_hndl;
	dma_addr_t dma;
	u32 val;

	desc = &pcie_priv->desc_data[0];

	if (desc->prx_ring) {
		desc->rx_buf_size = SYSADPT_MAX_AGGR_SIZE;

		for (i = 0; i < PCIE_MAX_NUM_RX_DESC; i++) {
			rx_hndl = &desc->rx_hndl[i];
			rx_hndl->psk_buff =
				dev_alloc_skb(desc->rx_buf_size);

			if (!rx_hndl->psk_buff) {
				wiphy_err(priv->hw->wiphy,
					  "rxdesc %i: no skbuff available\n",
					  i);
				return -ENOMEM;
			}

			skb_reserve(rx_hndl->psk_buff,
				    PCIE_MIN_BYTES_HEADROOM);
			desc->prx_ring[i].rx_control =
				EAGLE_RXD_CTRL_DRIVER_OWN;
			desc->prx_ring[i].status = EAGLE_RXD_STATUS_OK;
			desc->prx_ring[i].qos_ctrl = 0x0000;
			desc->prx_ring[i].channel = 0x00;
			desc->prx_ring[i].rssi = 0x00;
			desc->prx_ring[i].pkt_len =
				cpu_to_le16(SYSADPT_MAX_AGGR_SIZE);
			dma = pci_map_single(pcie_priv->pdev,
					     rx_hndl->psk_buff->data,
					     desc->rx_buf_size,
					     PCI_DMA_FROMDEVICE);
			if (pci_dma_mapping_error(pcie_priv->pdev, dma)) {
				wiphy_err(priv->hw->wiphy,
					  "failed to map pci memory!\n");
				return -ENOMEM;
			}
			desc->prx_ring[i].pphys_buff_data = cpu_to_le32(dma);
			val = (u32)desc->pphys_rx_ring +
			      ((i + 1) * sizeof(struct pcie_rx_desc));
			desc->prx_ring[i].pphys_next = cpu_to_le32(val);
			rx_hndl->pdesc = &desc->prx_ring[i];
			if (i < (PCIE_MAX_NUM_RX_DESC - 1))
				rx_hndl->pnext = &desc->rx_hndl[i + 1];
		}
		desc->prx_ring[PCIE_MAX_NUM_RX_DESC - 1].pphys_next =
			cpu_to_le32((u32)desc->pphys_rx_ring);
		desc->rx_hndl[PCIE_MAX_NUM_RX_DESC - 1].pnext =
			&desc->rx_hndl[0];
		desc->pnext_rx_hndl = &desc->rx_hndl[0];

		return 0;
	}

	wiphy_err(priv->hw->wiphy, "no valid RX mem\n");

	return -ENOMEM;
}

static void pcie_rx_ring_cleanup(struct mwl_priv *priv)
{
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;
	int i;
	struct pcie_rx_hndl *rx_hndl;

	desc = &pcie_priv->desc_data[0];

	if (desc->prx_ring) {
		for (i = 0; i < PCIE_MAX_NUM_RX_DESC; i++) {
			rx_hndl = &desc->rx_hndl[i];
			if (!rx_hndl->psk_buff)
				continue;

			pci_unmap_single(pcie_priv->pdev,
					 le32_to_cpu
					 (rx_hndl->pdesc->pphys_buff_data),
					 desc->rx_buf_size,
					 PCI_DMA_FROMDEVICE);

			dev_kfree_skb_any(rx_hndl->psk_buff);

			wiphy_info(priv->hw->wiphy,
				   "unmapped+free'd %i 0x%p 0x%x %i\n",
				   i, rx_hndl->psk_buff->data,
				   le32_to_cpu(rx_hndl->pdesc->pphys_buff_data),
				   desc->rx_buf_size);

			rx_hndl->psk_buff = NULL;
		}
	}
}

static void pcie_rx_ring_free(struct mwl_priv *priv)
{
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;

	desc = &pcie_priv->desc_data[0];

	if (desc->prx_ring) {
		pcie_rx_ring_cleanup(priv);

		dma_free_coherent(priv->dev,
				  MAX_NUM_RX_RING_BYTES,
				  desc->prx_ring,
				  desc->pphys_rx_ring);

		desc->prx_ring = NULL;
	}

	kfree(desc->rx_hndl);

	desc->pnext_rx_hndl = NULL;
}

static inline void pcie_rx_prepare_status(struct pcie_rx_desc *pdesc,
					  struct ieee80211_rx_status *status)
{
	u16 rate, format, nss, bw, gi, rt;

	memset(status, 0, sizeof(*status));

	status->signal = -(pdesc->rssi + W836X_RSSI_OFFSET);

	rate = le16_to_cpu(pdesc->rate);
	format = rate & MWL_RX_RATE_FORMAT_MASK;
	nss = (rate & MWL_RX_RATE_NSS_MASK) >> MWL_RX_RATE_NSS_SHIFT;
	bw = (rate & MWL_RX_RATE_BW_MASK) >> MWL_RX_RATE_BW_SHIFT;
	gi = (rate & MWL_RX_RATE_GI_MASK) >> MWL_RX_RATE_GI_SHIFT;
	rt = (rate & MWL_RX_RATE_RT_MASK) >> MWL_RX_RATE_RT_SHIFT;

	switch (format) {
	case RX_RATE_INFO_FORMAT_11N:
		status->flag |= RX_FLAG_HT;
		if (bw == RX_RATE_INFO_HT40)
			status->flag |= RX_FLAG_40MHZ;
		if (gi == RX_RATE_INFO_SHORT_INTERVAL)
			status->flag |= RX_FLAG_SHORT_GI;
		break;
	case RX_RATE_INFO_FORMAT_11AC:
		status->flag |= RX_FLAG_VHT;
		if (bw == RX_RATE_INFO_HT40)
			status->flag |= RX_FLAG_40MHZ;
		if (bw == RX_RATE_INFO_HT80)
			status->vht_flag |= RX_VHT_FLAG_80MHZ;
		if (bw == RX_RATE_INFO_HT160)
			status->vht_flag |= RX_VHT_FLAG_160MHZ;
		if (gi == RX_RATE_INFO_SHORT_INTERVAL)
			status->flag |= RX_FLAG_SHORT_GI;
		status->vht_nss = (nss + 1);
		break;
	}

	status->rate_idx = rt;

	if (pdesc->channel > BAND_24_CHANNEL_NUM) {
		status->band = NL80211_BAND_5GHZ;
		if ((!(status->flag & RX_FLAG_HT)) &&
		    (!(status->flag & RX_FLAG_VHT))) {
			status->rate_idx -= 5;
			if (status->rate_idx >= BAND_50_RATE_NUM)
				status->rate_idx = BAND_50_RATE_NUM - 1;
		}
	} else {
		status->band = NL80211_BAND_2GHZ;
		if ((!(status->flag & RX_FLAG_HT)) &&
		    (!(status->flag & RX_FLAG_VHT))) {
			if (status->rate_idx >= BAND_24_RATE_NUM)
				status->rate_idx = BAND_24_RATE_NUM - 1;
		}
	}

	status->freq = ieee80211_channel_to_frequency(pdesc->channel,
						      status->band);

	/* check if status has a specific error bit (bit 7) set or indicates
	 * a general decrypt error
	 */
	if ((pdesc->status == GENERAL_DECRYPT_ERR) ||
	    (pdesc->status & DECRYPT_ERR_MASK)) {
		/* check if status is not equal to 0xFF
		 * the 0xFF check is for backward compatibility
		 */
		if (pdesc->status != GENERAL_DECRYPT_ERR) {
			if (((pdesc->status & (~DECRYPT_ERR_MASK)) &
			    TKIP_DECRYPT_MIC_ERR) && !((pdesc->status &
			    (WEP_DECRYPT_ICV_ERR | TKIP_DECRYPT_ICV_ERR)))) {
				status->flag |= RX_FLAG_MMIC_ERROR;
			}
		}
	}
}

static inline int pcie_rx_refill(struct mwl_priv *priv,
				 struct pcie_rx_hndl *rx_hndl)
{
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;
	dma_addr_t dma;

	desc = &pcie_priv->desc_data[0];

	rx_hndl->psk_buff = dev_alloc_skb(desc->rx_buf_size);

	if (!rx_hndl->psk_buff)
		return -ENOMEM;

	skb_reserve(rx_hndl->psk_buff, PCIE_MIN_BYTES_HEADROOM);

	rx_hndl->pdesc->status = EAGLE_RXD_STATUS_OK;
	rx_hndl->pdesc->qos_ctrl = 0x0000;
	rx_hndl->pdesc->channel = 0x00;
	rx_hndl->pdesc->rssi = 0x00;
	rx_hndl->pdesc->pkt_len = cpu_to_le16(desc->rx_buf_size);

	dma = pci_map_single(pcie_priv->pdev,
			     rx_hndl->psk_buff->data,
			     desc->rx_buf_size,
			     PCI_DMA_FROMDEVICE);
	if (pci_dma_mapping_error(pcie_priv->pdev, dma)) {
		dev_kfree_skb_any(rx_hndl->psk_buff);
		wiphy_err(priv->hw->wiphy,
			  "failed to map pci memory!\n");
		return -ENOMEM;
	}

	rx_hndl->pdesc->pphys_buff_data = cpu_to_le32(dma);

	return 0;
}

int pcie_rx_init(struct ieee80211_hw *hw)
{
	struct mwl_priv *priv = hw->priv;
	int rc;

	rc = pcie_rx_ring_alloc(priv);
	if (rc) {
		wiphy_err(hw->wiphy, "allocating RX ring failed\n");
		return rc;
	}

	rc = pcie_rx_ring_init(priv);
	if (rc) {
		pcie_rx_ring_free(priv);
		wiphy_err(hw->wiphy,
			  "initializing RX ring failed\n");
		return rc;
	}

	return 0;
}

void pcie_rx_deinit(struct ieee80211_hw *hw)
{
	struct mwl_priv *priv = hw->priv;

	pcie_rx_ring_cleanup(priv);
	pcie_rx_ring_free(priv);
}

void pcie_rx_recv(unsigned long data)
{
	struct ieee80211_hw *hw = (struct ieee80211_hw *)data;
	struct mwl_priv *priv = hw->priv;
	struct pcie_priv *pcie_priv = priv->hif.priv;
	struct pcie_desc_data *desc;
	struct pcie_rx_hndl *curr_hndl;
	int work_done = 0;
	struct sk_buff *prx_skb = NULL;
	int pkt_len;
	struct ieee80211_rx_status status;
	struct mwl_vif *mwl_vif = NULL;
	struct ieee80211_hdr *wh;

	desc = &pcie_priv->desc_data[0];
	curr_hndl = desc->pnext_rx_hndl;

	if (!curr_hndl) {
		pcie_mask_int(pcie_priv, MACREG_A2HRIC_BIT_RX_RDY, true);
		pcie_priv->is_rx_schedule = false;
		wiphy_warn(hw->wiphy, "busy or no receiving packets\n");
		return;
	}

	while ((curr_hndl->pdesc->rx_control == EAGLE_RXD_CTRL_DMA_OWN) &&
	       (work_done < pcie_priv->recv_limit)) {
		prx_skb = curr_hndl->psk_buff;
		if (!prx_skb)
			goto out;
		pci_unmap_single(pcie_priv->pdev,
				 le32_to_cpu(curr_hndl->pdesc->pphys_buff_data),
				 desc->rx_buf_size,
				 PCI_DMA_FROMDEVICE);
		pkt_len = le16_to_cpu(curr_hndl->pdesc->pkt_len);

		if (skb_tailroom(prx_skb) < pkt_len) {
			dev_kfree_skb_any(prx_skb);
			goto out;
		}

		if (curr_hndl->pdesc->channel !=
		    hw->conf.chandef.chan->hw_value) {
			dev_kfree_skb_any(prx_skb);
			goto out;
		}

		pcie_rx_prepare_status(curr_hndl->pdesc, &status);

		priv->noise = -curr_hndl->pdesc->noise_floor;

		wh = &((struct pcie_dma_data *)prx_skb->data)->wh;

		if (ieee80211_has_protected(wh->frame_control)) {
			/* Check if hw crypto has been enabled for
			 * this bss. If yes, set the status flags
			 * accordingly
			 */
			if (ieee80211_has_tods(wh->frame_control)) {
				mwl_vif = utils_find_vif_bss(priv, wh->addr1);
				if (!mwl_vif &&
				    ieee80211_has_a4(wh->frame_control))
					mwl_vif =
						utils_find_vif_bss(priv,
								   wh->addr2);
			} else {
				mwl_vif = utils_find_vif_bss(priv, wh->addr2);
			}

			if  ((mwl_vif && mwl_vif->is_hw_crypto_enabled) ||
			     is_multicast_ether_addr(wh->addr1) ||
			     (ieee80211_is_mgmt(wh->frame_control) &&
			     ieee80211_has_protected(wh->frame_control) &&
			     !is_multicast_ether_addr(wh->addr1))) {
				/* When MMIC ERROR is encountered
				 * by the firmware, payload is
				 * dropped and only 32 bytes of
				 * mwlwifi Firmware header is sent
				 * to the host.
				 *
				 * We need to add four bytes of
				 * key information.  In it
				 * MAC80211 expects keyidx set to
				 * 0 for triggering Counter
				 * Measure of MMIC failure.
				 */
				if (status.flag & RX_FLAG_MMIC_ERROR) {
					struct pcie_dma_data *dma_data;

					dma_data = (struct pcie_dma_data *)
					     prx_skb->data;
					memset((void *)&dma_data->data, 0, 4);
					pkt_len += 4;
				}

				if (!ieee80211_is_auth(wh->frame_control))
					status.flag |= RX_FLAG_IV_STRIPPED |
						       RX_FLAG_DECRYPTED |
						       RX_FLAG_MMIC_STRIPPED;
			}
		}

		skb_put(prx_skb, pkt_len);
		pcie_rx_remove_dma_header(prx_skb, curr_hndl->pdesc->qos_ctrl);

		wh = (struct ieee80211_hdr *)prx_skb->data;

		if (ieee80211_is_data_qos(wh->frame_control)) {
			const u8 eapol[] = {0x88, 0x8e};
			u8 *qc = ieee80211_get_qos_ctl(wh);
			u8 *data;

			data = prx_skb->data +
				ieee80211_hdrlen(wh->frame_control) + 6;

			if (!memcmp(data, eapol, sizeof(eapol)))
				*qc |= 7;
		}

		memcpy(IEEE80211_SKB_RXCB(prx_skb), &status, sizeof(status));
		ieee80211_rx(hw, prx_skb);
out:
		pcie_rx_refill(priv, curr_hndl);
		curr_hndl->pdesc->rx_control = EAGLE_RXD_CTRL_DRIVER_OWN;
		curr_hndl->pdesc->qos_ctrl = 0;
		curr_hndl = curr_hndl->pnext;
		work_done++;
	}

	desc->pnext_rx_hndl = curr_hndl;
	pcie_mask_int(pcie_priv, MACREG_A2HRIC_BIT_RX_RDY, true);
	pcie_priv->is_rx_schedule = false;
}
