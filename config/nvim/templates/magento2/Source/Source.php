<?php

namespace [[magento2.namespace]];

use Magento\Framework\Data\OptionSourceInterface;

/**
 * Class [[php.class]]
 *
 * @author [[author]] <[[author_contact]]>
 */
class [[php.class]] implements OptionSourceInterface
{
    protected $options = [
        // '0' => 'Zero',
        // '1' => 'One',[[_]]
    ];

    /**
     * Get options
     *
     * @return array
     */
    public function toOptionArray()
    {
        $options = [];
        foreach ($this->options as $key => $value) {
            $options[] = [
                'label' => $value,
                'value' => $key,
            ];
        }
        return $options;
    }
}
